/*
Main script for building and running the playground.

TODO:

- [ ] Better css reloading

*/

import fs            from "node:fs"
import fsp           from "node:fs/promises"
import path          from "node:path"
import url           from "node:url"
import http          from "node:http"
import process       from "node:process"
import child_process from "node:child_process"
import * as chokidar from "chokidar"
import * as ws       from "ws"
import * as rollup   from "rollup"
import * as swc      from "@swc/core"

import {
	DIST_DIRNAME, CONFIG_FILENAME, HTTP_PORT, MESSAGE_RELOAD, PACKAGE_DIRNAME, PLAYGROUND_DIRNAME,
	WASM_PATH, WEB_SOCKET_PORT, CONFIG_OUT_FILENAME, WASM_FILENAME, PUBLIC_DIRNAME,
} from "./config.js"

const dirname         = path.dirname(url.fileURLToPath(import.meta.url))
const playground_path = path.join(dirname, PLAYGROUND_DIRNAME)
const dist_path       = path.join(dirname, DIST_DIRNAME)
const config_path     = path.join(dirname, CONFIG_FILENAME)
const config_path_out = path.join(playground_path, CONFIG_OUT_FILENAME)
const public_path     = path.join(playground_path, PUBLIC_DIRNAME)
const shdc_dir_path   = path.join(dirname, "shdc")
const shdc_bin_path   = path.join(dirname, "shdc.bin")


/** @type {string[]} */
const ODIN_ARGS_SHARED = [
	"build",
	playground_path,
	"-out:"+WASM_PATH,
	"-target:js_wasm32",
]
/** @type {string[]} */
const ODIN_ARGS_DEV    = [
]
/** @type {string[]} */
const ODIN_ARGS_RELESE = [
	"-vet-unused",
	"-vet-style",
	"-vet-semicolon",
	"-o:aggressive",
	"-disable-assert",
	"-no-bounds-check",
	"-obfuscate-source-code-locations",
]
const ODIN_ARGS_SHDC = [
	"build",
	shdc_dir_path,
	"-out:"+shdc_bin_path,
	"-vet-unused",
	"-vet-style",
	"-vet-semicolon",
	"-o:aggressive",
	"-microarch:native",
	"-disable-assert",
	"-no-bounds-check",
	"-obfuscate-source-code-locations",
]

/*
Allow passing odin compiler flags to the script.
Example:
	node main.js -odin:-debug
	npm run dev -- -odin:-debug
*/
for (let i = 2; i < process.argv.length; i++) {
	const arg = process.argv[i]
	if (arg.startsWith("-odin:")) {
		const flag = arg.substring(6)
		ODIN_ARGS_SHARED.push(flag)
	}
}

/** @enum {(typeof Command)[keyof typeof Command]} */
const Command = /** @type {const} */ ({
	Server    : "server",     // Start a dev server
	Preview   : "preview",    // Start a static server that serves the dist dir
	Build     : "build",      // Build the example page
	Build_SHDC: "build-shdc", // Rebuild the SHDC binary
	shdc      : "shdc",       // Generate shader utils
})

/** @type {Record<Command, (args: string[]) => void>} */
const command_handlers = {
	[Command.Server]() {
		/* Make sure the dist dir exists */
		void fs.mkdirSync(dist_path, {recursive: true})

		const server = makeHttpServer(requestListener)
		const wss = new ws.WebSocketServer({port: WEB_SOCKET_PORT})

		let wasm_build_promise =
			build_shdc()
			.then(() => build_shader_utils())
			.then(() => build_wasm(true))
		const config_promise = build_config(true)

		const watcher = chokidar.watch(
			[
				`./${PLAYGROUND_DIRNAME}/**/*.{js,html,css,odin,vert,frag}`,
				`./${PACKAGE_DIRNAME}/**/*.{js,odin}`,
			],
			{
				ignored: ["**/.*", "**/_*", "**/*.test.js"],
				ignoreInitial: true,
			},
		)
		void watcher.on("change", filepath => {
			switch (path.extname(filepath)) {
			case ".odin":
				info("Rebuilding WASM...")
				wasm_build_promise = build_wasm(true)
				break
			case ".vert":
			case ".frag":
				info("Rebuilding shader utils...")
				wasm_build_promise = build_shader_utils()
				break
			}

			info("Reloading page...")
			sendToAllClients(wss, MESSAGE_RELOAD)
		})

		function exit() {
			void server.close()
			void wss.close()
			void watcher.close()
			sendToAllClients(wss, MESSAGE_RELOAD)
			void process.exit(0)
		}
		void process.on("SIGINT", exit)
		void process.on("SIGTERM", exit)

		/** @returns {Promise<void>} */
		async function requestListener(
			/** @type {http.IncomingMessage} */ req,
			/** @type {http.ServerResponse} */ res,
		) {
			const req_time = performance.now()
			if (!req.url || req.method !== "GET") return end404(req, res, req_time)

			if (req.url === "/" + CONFIG_OUT_FILENAME) {
				await config_promise
			} else if (req.url === "/" + WASM_FILENAME) {
				await wasm_build_promise
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

			if (!exists) return end404(req, res, req_time)

			streamStatic(req, res, filepath, req_time)
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
			const req_time = performance.now()

			// /* Simulate delay */
			// await sleep(300)

			if (!req.url || req.method !== "GET") return end404(req, res, req_time)

			const relative_filepath = toWebFilepath(req.url)
			const filepath = path.join(dist_path, relative_filepath)
			const exists = await fileExists(filepath)

			if (!exists) return end404(req, res, req_time)

			streamStatic(req, res, filepath, req_time)
		}

		void process.on("SIGINT", () => {
			void server.close()
			void process.exit(0)
		})
	},
	async [Command.Build]() {
		const logger = make_logger("BUILD")

		/* Clean dist dir */
		await ensureEmptyDir(dist_path)
		logger_info(logger, "Cleared dist dir")

		/*
		During build, building shdc, and generating shader utils is skipped
		this is because they are comminted to the repo, and are not expected to change
		*/
		const wasm_promise = build_wasm(false)

		await build_config(false)
		logger_info(logger, "Built config")

		const bundle_res = await unsafePromiseToError(
			rollup.rollup({input: path.join(playground_path, "setup.js")}),
		)
		if (bundle_res instanceof Error) panic("Failed to bundle, error:", bundle_res)
		else logger_info(logger, "Bundled")

		const generate_res = await unsafePromiseToError(bundle_res.generate({}))
		if (generate_res instanceof Error) panic("Failed to generate, error:", generate_res)
		else logger_info(logger, "Generated")

		let errors_count = 0

		const promises = generate_res.output.map(async chunk => {
			if (chunk.type === "asset") {
				error("Unexpected asset: "+chunk.fileName)
				errors_count += 1
				return
			}

			const transformed = await swc.transform(chunk.code, {
				jsc: JSC_CONFIG,
				minify: true,
				filename: chunk.fileName,
			})

			return fsp.writeFile(path.join(dist_path, chunk.fileName), transformed.code)
		})

		await Promise.all(promises)
		void bundle_res.close()
		logger_info(logger, "Transformed")

		errors_count
			? logger_error(logger, "JS Build failed, errors: "+errors_count)
			: logger_info(logger, "JS Build complete")

		const wasm_exit_code = await wasm_promise
		if (wasm_exit_code != 0) panic("Failed to build WASM, code:", wasm_exit_code)

		/* Copy public dir */
		await copyDirContents(public_path, dist_path)

		logger_success(logger, "Build complete")

		process.exit(0)
	},
	[Command.Build_SHDC]() {
		fs.rmSync(shdc_bin_path, {force: true})
		build_shdc()
	},
	[Command.shdc]() {
		build_shdc()
		build_shader_utils()
	},
}

/** @type {<O extends Object>(o: O, k: PropertyKey | keyof O) => k is keyof O} */
const hasKey = (o, k) => o.hasOwnProperty(k)

const args = process.argv.slice(2)
const command = args[0]

if (!command) panic("Command not specified")
if (!hasKey(command_handlers, command)) panic("Unknown command", command)

const command_handler = command_handlers[command]
command_handler(args.slice(1))

/** @type {swc.JscConfig} */
const JSC_CONFIG = {
	target: "es2018",
	keepClassNames: false,
	loose: false,
	externalHelpers: false,
	minify: {
		compress: true,
		mangle: true,
		inlineSourcesContent: true,
	},
}

/** @returns {Promise<number>} exit code */
async function build_shader_utils() {
	const start = performance.now()

	const child = child_process.execFile(shdc_bin_path, args, {cwd: dirname})
	const code = await childProcessToPromise(child)

	if (code === 0) {
		info(`Shader utils built in: ${Math.round(performance.now() - start)}ms`)
	} else {
		error("Shader utils build failed");
	}

	return code
}

/** @returns {Promise<number>} exit code */
async function build_shdc() {
	const start = performance.now()

	if (await fileExists(shdc_bin_path)) {
		return 0
	}

	const child = child_process.execFile("odin", ODIN_ARGS_SHDC, {cwd: dirname})

	child.stderr?.on("data", console.error)

	const code = await childProcessToPromise(child)

	if (code === 0) {
		info(`SHDC built in: ${Math.round(performance.now() - start)}ms`)
	} else {
		error("SHDC build failed");
	}

	return code
}

/**
 * @param   {boolean}         is_dev
 * @returns {Promise<number>}            exit code
 */
async function build_wasm(is_dev) {
	const start = performance.now()

	const args = ODIN_ARGS_SHARED.concat(is_dev ? ODIN_ARGS_DEV : ODIN_ARGS_RELESE)

	const child = child_process.execFile("odin", args, {cwd: dirname})
	child.stderr?.on("data", data => {
		console.error(data.toString())
	})

	const code = await childProcessToPromise(child)

	if (code === 0) {
		info(`WASM built in: ${Math.round(performance.now() - start)}ms`)
	} else {
		error("WASM build failed");
	}

	return code
}

/**
 * Copy the config file to the playground source dir, with a correct env mode.
 *
 * @param   {boolean}       is_dev
 * @returns {Promise<void>}
 */
async function build_config(is_dev) {
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

	// "\x1b[90m"+message+"\x1b[0m");
	console.log("\x1b[90m"+`//`+"\x1b[0m")
	console.log("\x1b[90m"+`//`+"\x1b[0m"+` Server running at http://127.0.0.1:${HTTP_PORT}`)
	console.log("\x1b[90m"+`//`+"\x1b[0m")

	return server
}

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @param   {number}               req_time
 * @returns {void}
 */
function end404(req, res, req_time) {
	void res.writeHead(404)
	void res.end()
	log_request(req, res, req_time)
}

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @param   {string}               filepath
 * @param   {number}               req_time
 * @returns {void}                 */
function streamStatic(req, res, filepath, req_time) {
	const ext = toExt(filepath)
	const mime_type = mimeType(ext)
	void res.writeHead(200, {"Content-Type": mime_type})

	const stream = fs.createReadStream(filepath)
	void stream.pipe(res)

	log_request(req, res, req_time)
}

function info (/** @type {string} */ message) {
	console.log("\x1b[90m"+message+"\x1b[0m");
}
function success (/** @type {string} */ message) {
	console.log("\x1b[32m"+message+"\x1b[0m")
}
function error (/** @type {string} */ message) {
	console.error("\x1b[31m"+message+"\x1b[0m")
}

/** @returns {never} */
function panic(/** @type {any[]} */ ...message) {
	error(...message)
	process.exit(1)
}

/**
 * @typedef {object} Logger
 * @property {string} prefix
 * @property {number} time
 */

/**
 * @param   {string} prefix
 * @returns {Logger} */
function make_logger(/** @type {string} */ prefix) {
	return {
		prefix: prefix,
		time  : performance.now(),
	}
}
/**
 * @param {Logger} logger
 * @param {string} message
 * @returns {void} */
function logger_info(logger, message) {
	const now = performance.now()
	console.log("\x1b[90m"+`${logger.prefix} [${Math.round(now - logger.time)}ms] ${message}`+"\x1b[0m")
	logger.time = now
}
/**
 * @param {Logger} logger
 * @param {string} message
 * @returns {void} */
function logger_success(logger, message) {
	const now = performance.now()
	console.log("\x1b[32m"+`${logger.prefix} [${Math.round(now - logger.time)}ms] ${message}`+"\x1b[0m")
	logger.time = now
}
/**
 * @param {Logger} logger
 * @param {string} message
 * @returns {void} */
function logger_error(logger, message) {
	const now = performance.now()
	console.error("\x1b[31m"+`${logger.prefix} [${Math.round(now - logger.time)}ms] ${message}`+"\x1b[0m")
	logger.time = now
}

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @param   {number}               req_time
 * @returns {void} */
function log_request(req, res, req_time) {
	let txt = req.method ?? "NULL"
	txt += " "
	txt += res.statusCode === 200
		? "\x1b[32m" // green
		: "\x1b[31m" // red
	txt += res.statusCode
	txt += "\x1b[0m"
	txt += " "
	const time = Math.round(performance.now() - req_time)
	txt +=
		  time < 100 ? "\x1b[32m" // green
		: time < 500 ? "\x1b[33m" // yellow
		:              "\x1b[31m" // red
	txt += time
	txt += "ms"
	txt += "\x1b[0m"
	txt += " "
	txt += req.url ?? "NULL"
	console.log(txt)
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
	case "html": return "text/html; charset=UTF-8"
	case "js":
	case "mjs":  return "application/javascript"
	case "json": return "application/json"
	case "wasm": return "application/wasm"
	case "css":  return "text/css"
	case "png":  return "image/png"
	case "jpg":  return "image/jpg"
	case "gif":  return "image/gif"
	case "ico":  return "image/x-icon"
	case "svg":  return "image/svg+xml"
	default:     return "application/octet-stream"
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

/**
 * @param   {number}        ms
 * @returns {Promise<void>}
 */
function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms))
}

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
