import * as fs from "node:fs"
import * as fsp from "node:fs/promises"
import * as path from "node:path"
import * as url from "node:url"
import * as http from "node:http"
import * as child_process from "node:child_process"
import * as chokidar from "chokidar"
import * as ws from "ws"
import * as rollup from "rollup"
import * as terser from "terser"

import {
	DIST_DIRNAME,
	CONFIG_FILENAME,
	HTTP_PORT,
	MESSAGE_RELOAD,
	PACKAGE_DIRNAME,
	PLAYGROUND_DIRNAME,
	WASM_PATH,
	WEB_SOCKET_PORT,
	CONFIG_OUT_FILENAME,
	SCRIPT_FILENAME,
	WASM_FILENAME,
	PUBLIC_DIRNAME,
} from "./config.js"

const dirname = path.dirname(url.fileURLToPath(import.meta.url))
const playground_path = path.join(dirname, PLAYGROUND_DIRNAME)
const dist_path = path.join(dirname, DIST_DIRNAME)
const config_path = path.join(dirname, CONFIG_FILENAME)
const config_path_out = path.join(playground_path, CONFIG_OUT_FILENAME)
const public_path = path.join(playground_path, PUBLIC_DIRNAME)

const DEBUG_ODIN_ARGS = ["-debug"]
const RELESE_ODIN_ARGS = [
	"-vet-unused",
	"-vet-shadowing",
	"-vet-style",
	"-vet-semicolon",
	"-o:speed",
	"-disable-assert",
	"-no-bounds-check",
	"-obfuscate-source-code-locations",
]

/** @enum {string} */
const Command = {
	/* Start a dev server, with server hot reload */
	Dev: "dev",
	/* Start a dev server */
	Server: "server",
	/* Start a static server that serves the dist dir */
	Preview: "preview",
	/* Build the example page */
	Build: "build",
}

/** @type {Record<Command, (args: string[]) => void>} */
const command_handlers = {
	[Command.Dev]() {
		let child = makeChildServer()

		const watcher = chokidar.watch(["./*.js"], {
			ignored: "**/.*",
			ignoreInitial: true,
		})
		void watcher.on("change", () => {
			// eslint-disable-next-line no-console
			console.log("Stopping server...")
			const ok = child.kill("SIGINT")
			// eslint-disable-next-line no-console
			if (!ok) console.log("Failed to kill server")

			child = makeChildServer()
		})
	},
	[Command.Server]() {
		/* Make sure the dist dir exists */
		void fs.mkdirSync(dist_path, {recursive: true})

		const server = makeHttpServer(requestListener)
		const wss = makeWebSocketServer()

		let wasm_build_promise = buildWASM(false)
		const config_promise = buildConfig(true)

		const watcher = chokidar.watch(
			[
				`./${PLAYGROUND_DIRNAME}/**/*.{js,html,odin,glsl}`,
				`./${PACKAGE_DIRNAME}/**/*.{js,odin}`,
			],
			{
				ignored: ["**/.*", "**/_*", "**/*.test.js"],
				ignoreInitial: true,
			},
		)
		void watcher.on("change", filepath => {
			if (filepath.endsWith(".odin") || filepath.endsWith(".glsl")) {
				// eslint-disable-next-line no-console
				console.log("Rebuilding WASM...")
				wasm_build_promise = buildWASM(false)
			}
			// eslint-disable-next-line no-console
			console.log("Reloading page...")
			sendToAllClients(wss, MESSAGE_RELOAD)
		})

		void process.on("SIGINT", () => {
			void server.close()
			void wss.close()
			void watcher.close()
			sendToAllClients(wss, MESSAGE_RELOAD)
			void process.exit(0)
		})

		/** @returns {Promise<void>} */
		async function requestListener(
			/** @type {http.IncomingMessage} */ req,
			/** @type {http.ServerResponse} */ res,
		) {
			if (!req.url || req.method !== "GET") return end404(req, res)

			if (req.url === "/" + CONFIG_FILENAME) {
				await config_promise
			} else if (req.url === "/" + WASM_FILENAME) {
				const code = await wasm_build_promise
				if (code !== 0) return end404(req, res)
			}

			/* Static files */
			const relative_filepath = toWebFilepath(req.url)

			let filepath = path.join(public_path, relative_filepath)
			let exists = await fileExists(filepath)

			if (!exists) {
				filepath = path.join(playground_path, relative_filepath)
				exists = await fileExists(filepath)
			}

			if (!exists) {
				filepath = path.join(dirname, relative_filepath)
				exists = await fileExists(filepath)
			}

			if (!exists) return end404(req, res)

			streamStatic(req, res, filepath)
		}
	},
	[Command.Preview]() {
		const server = makeHttpServer(requestListener)

		/**
		 * @param   {http.IncomingMessage} req
		 * @param   {http.ServerResponse}  res
		 * @returns {Promise<void>}
		 */
		async function requestListener(req, res) {
			// /* Simulate delay */
			// await sleep(300)

			if (!req.url || req.method !== "GET") return end404(req, res)

			const relative_filepath = toWebFilepath(req.url)
			const filepath = path.join(dist_path, relative_filepath)
			const exists = await fileExists(filepath)

			if (!exists) return end404(req, res)

			streamStatic(req, res, filepath)
		}

		void process.on("SIGINT", () => {
			void server.close()
			void process.exit(0)
		})
	},
	async [Command.Build]() {
		/* Clean dist dir */
		await ensureEmptyDir(dist_path)

		const wasm_promise = buildWASM(true)
		await buildConfig(false)

		const bundle_res = await unsafePromiseToError(
			rollup.rollup({input: path.join(playground_path, "index.js")}),
		)
		if (bundle_res instanceof Error) panic("Failed to bundle, error:", bundle_res)

		const generate_res = await unsafePromiseToError(bundle_res.generate({}))
		if (generate_res instanceof Error) panic("Failed to generate, error:", generate_res)

		let errors_count = 0

		const promises = generate_res.output.map(async chunk => {
			if (chunk.type === "asset") {
				// eslint-disable-next-line no-console
				console.error("Unexpected asset:", chunk.fileName)
				errors_count += 1
				return
			}

			const minified = await unsafePromiseToError(terser.minify(chunk.code, {module: true}))

			if (minified instanceof Error) {
				// eslint-disable-next-line no-console
				console.error("Failed to minify " + chunk.fileName + ":", minified)
				errors_count += 1
				return
			}

			if (typeof minified.code !== "string") {
				// eslint-disable-next-line no-console
				console.error("No code for minified chunk:", chunk.fileName)
				errors_count += 1
				return
			}

			return fsp.writeFile(path.join(dist_path, chunk.fileName), minified.code)
		})

		await Promise.all(promises)

		void bundle_res.close()

		errors_count
			? // eslint-disable-next-line no-console
				console.error("JS Build failed, errors:", errors_count)
			: // eslint-disable-next-line no-console
				console.log("JS Build complete")

		const wasm_exit_code = await wasm_promise
		if (wasm_exit_code != 0) panic("Failed to build WASM, code:", wasm_exit_code)

		/* Copy public dir */
		await copyDirContents(public_path, dist_path)

		// eslint-disable-next-line no-console
		console.log("Build complete")

		process.exit(0)
	},
}

const args = process.argv.slice(2)
const command = args[0]
if (!command) panic("Command not specified")

const command_handler = command_handlers[command]
if (!command_handler) panic("Unknown command", command)

command_handler(args.slice(1))

/** @returns {child_process.ChildProcess} */
function makeChildServer() {
	return child_process.spawn("node", [SCRIPT_FILENAME, Command.Server], {
		stdio: "inherit",
	})
}

/**
 * @param   {boolean}         is_release
 * @returns {Promise<number>}            exit code
 */
function buildWASM(is_release) {
	const args = ["build", playground_path, "-out:" + WASM_PATH, "-target:js_wasm32"]
	args.push.apply(args, is_release ? RELESE_ODIN_ARGS : DEBUG_ODIN_ARGS)

	const child = child_process.execFile("odin", args, {cwd: dirname})
	child.stderr?.on("data", data => {
		// eslint-disable-next-line no-console
		console.error(data.toString())
	})

	return childProcessToPromise(child)
}

/**
 * Copy the config file to the playground source dir, with a correct env mode.
 *
 * @param   {boolean}       is_dev
 * @returns {Promise<void>}
 */
async function buildConfig(is_dev) {
	const content = await fsp.readFile(config_path, "utf8")
	const corrected =
		"/* THIS FILE IS AUTO GENERATED, DO NOT EDIT */\n" +
		"export const IS_DEV = /** @type {boolean} */ (" +
		is_dev +
		")\n" +
		shiftLines(content, 1)
	await fsp.writeFile(config_path_out, corrected)
}

/**
 * @param   {http.RequestListener} requestListener
 * @returns {http.Server}
 */
function makeHttpServer(requestListener) {
	const server = http.createServer(requestListener).listen(HTTP_PORT)

	// eslint-disable-next-line no-console
	console.log(`//
// Server running at http://127.0.0.1:${HTTP_PORT}
//`)

	return server
}

/** @returns {ws.WebSocketServer} */
function makeWebSocketServer() {
	const wss = new ws.WebSocketServer({port: WEB_SOCKET_PORT})

	// eslint-disable-next-line no-console
	console.log(`//
// WebSocket server running at http://127.0.0.1:${WEB_SOCKET_PORT}
//`)

	return wss
}

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @returns {void}
 */
function end404(req, res) {
	void res.writeHead(404)
	void res.end()
	// eslint-disable-next-line no-console
	console.log(`${req.method} ${req.url} 404`)
}

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @param   {string}               filepath
 * @returns {void}
 */
function streamStatic(req, res, filepath) {
	const ext = toExt(filepath)
	const mime_type = mimeType(ext)
	void res.writeHead(200, {"Content-Type": mime_type})

	const stream = fs.createReadStream(filepath)
	void stream.pipe(res)

	// eslint-disable-next-line no-console
	console.log(`${req.method} ${req.url} 200`)
}

/** @returns {never} */
function panic(/** @type {any[]} */ ...message) {
	// eslint-disable-next-line no-console
	console.error(...message)
	process.exit(1)
}

/** @typedef {Parameters<ws.WebSocket["send"]>[0]} BufferLike */

/** @returns {void} */
function sendToAllClients(/** @type {ws.WebSocketServer} */ wss, /** @type {BufferLike} */ data) {
	for (const client of wss.clients) {
		client.send(data)
	}
}

/** @returns {string} */
function mimeType(/** @type {string} */ ext) {
	switch (ext) {
		case "html":
			return "text/html; charset=UTF-8"
		case "js":
		case "mjs":
			return "application/javascript"
		case "json":
			return "application/json"
		case "wasm":
			return "application/wasm"
		case "css":
			return "text/css"
		case "png":
			return "image/png"
		case "jpg":
			return "image/jpg"
		case "gif":
			return "image/gif"
		case "ico":
			return "image/x-icon"
		case "svg":
			return "image/svg+xml"
		default:
			return "application/octet-stream"
	}
}

function trueFn() {
	return true
}
function falseFn() {
	return false
}

/**
 * @template T
 * @param   {Promise<T>}         promise
 * @returns {Promise<T | Error>}
 */
function unsafePromiseToError(promise) {
	return promise.then(
		result => result,
		error => error,
	)
}

/** @returns {Promise<boolean>} */
function unsafePromiseToBool(/** @type {Promise<any>} */ promise) {
	return promise.then(trueFn, falseFn)
}

/** @returns {Promise<number>} Exit code */
function childProcessToPromise(/** @type {child_process.ChildProcess} */ child) {
	return new Promise(resolve => {
		void child.on("close", resolve)
	})
}

// /**
//  * @param   {number}        ms
//  * @returns {Promise<void>}
//  */
// function sleep(ms) {
// 	return new Promise(resolve => setTimeout(resolve, ms))
// }

/** @returns {string} */
function toWebFilepath(/** @type {string} */ path) {
	return path.endsWith("/") ? path + "index.html" : path
}

/** @returns {Promise<boolean>} */
function fileExists(/** @type {string} */ filepath) {
	return unsafePromiseToBool(fsp.access(filepath))
}

/**
 * @param   {fs.PathLike}   dirpath
 * @returns {Promise<void>}
 */
function ensureEmptyDir(dirpath) {
	return fsp.rm(dirpath, {recursive: true, force: true}).then(() => fsp.mkdir(dirpath))
}

/**
 * @param   {string}        src
 * @param   {string}        dest
 * @returns {Promise<void>}
 */
async function copyDirContents(src, dest) {
	const files = await fsp.readdir(src)
	const promises = files.map(async file => {
		const srcFile = path.join(src, file)
		const destFile = path.join(dest, file)
		const stats = await fsp.stat(srcFile)
		if (stats.isDirectory()) {
			await copyDir(srcFile, destFile)
		} else {
			await fsp.copyFile(srcFile, destFile)
		}
	})
	await Promise.all(promises)
}

/**
 * @param   {string}        src
 * @param   {string}        dest
 * @returns {Promise<void>}
 */
function copyDir(src, dest) {
	return fsp.mkdir(dest).then(() => copyDirContents(src, dest))
}

/** @returns {string} */
function toExt(/** @type {string} */ filepath) {
	return path.extname(filepath).substring(1).toLowerCase()
}

/** @returns {string} */
function shiftLines(/** @type {string} */ str, /** @type {number} */ lines) {
	while (lines > 0) {
		str = str.substring(str.indexOf("\n") + 1)
		lines--
	}

	return str
}
