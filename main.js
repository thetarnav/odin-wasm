import * as fs from "node:fs"
import * as fsp from "node:fs/promises"
import * as path from "node:path"
import * as url from "node:url"
import * as http from "node:http"
import * as child_process from "node:child_process"
import * as chokidar from "chokidar"
import * as ws from "ws"

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
} from "./config.js"

const dirname = path.dirname(url.fileURLToPath(import.meta.url))
const playground_path = path.join(dirname, PLAYGROUND_DIRNAME)
const dist_path = path.join(dirname, DIST_DIRNAME)
const config_path = path.join(dirname, CONFIG_FILENAME)
const config_out_path = path.join(playground_path, CONFIG_OUT_FILENAME)

const args = process.argv.slice(2)

/** @enum {string} */
const Command = {
	Dev: "dev",
	Server: "server",
}

switch (args[0]) {
	case Command.Dev: {
		/** @type {child_process.ChildProcess} */
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

		break
	}
	case Command.Server: {
		/* Make sure the dist dir exists */
		void fs.mkdirSync(dist_path, {recursive: true})

		const server = http.createServer(requestListener).listen(HTTP_PORT)
		const wss = new ws.WebSocketServer({port: WEB_SOCKET_PORT})

		// eslint-disable-next-line no-console
		console.log(`
Server running at http://127.0.0.1:${HTTP_PORT}
WebSocket server running at http://127.0.0.1:${WEB_SOCKET_PORT}
`)

		let wasm_build_promise = buildWASM()
		const config_promise = buildConfig()

		const watcher = chokidar.watch(
			[`./${PLAYGROUND_DIRNAME}/**/*.{js,html,odin}`, `./${PACKAGE_DIRNAME}/**/*.{js,odin}`],
			{
				ignored: ["**/.*", "**/_*", "**/*.test.js"],
				ignoreInitial: true,
			},
		)
		void watcher.on("change", filepath => {
			if (filepath.endsWith(".odin")) {
				// eslint-disable-next-line no-console
				console.log("Rebuilding WASM...")
				wasm_build_promise = buildWASM()
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
			if (!req.url || req.method !== "GET") return end404()

			if (req.url === "/" + CONFIG_FILENAME) {
				await config_promise
			} else if (req.url === "/" + WASM_PATH) {
				const code = await wasm_build_promise
				if (code !== 0) return end404()
			} else if (req.url === "/" || req.url === "/index.html") {
				req.url = "/" + PLAYGROUND_DIRNAME + "/index.html"
			}

			/* Static files */
			const relative_filepath = toWebFilepath(req.url)
			const filepath = path.join(dirname, relative_filepath)

			const exists = await fileExists(filepath)
			if (!exists) return end404()

			const ext = toExt(filepath)
			const mime_type = mimeType(ext)
			void res.writeHead(200, {"Content-Type": mime_type})

			const stream = fs.createReadStream(filepath)
			void stream.pipe(res)

			// eslint-disable-next-line no-console
			console.log(`${req.method} ${req.url} 200`)
		}

		function end404(
			/** @type {http.IncomingMessage} */ req,
			/** @type {http.ServerResponse} */ res,
		) {
			void res.writeHead(404)
			void res.end()
			// eslint-disable-next-line no-console
			console.log(`${req.method} ${req.url} 404`)
		}

		break
	}
	default: {
		// eslint-disable-next-line no-console
		console.error("Unknown command", args[0])
	}
}

/** @returns {child_process.ChildProcess} */
function makeChildServer() {
	return child_process.spawn("node", [SCRIPT_FILENAME, Command.Server], {
		stdio: "inherit",
	})
}

/** @returns {Promise<number>} exit code */
function buildWASM() {
	const child = child_process.execFile(
		"odin",
		["build", playground_path, "-out:" + WASM_PATH, "-target:js_wasm32"],
		{cwd: dirname},
	)
	child.stderr?.on("data", data => {
		// eslint-disable-next-line no-console
		console.error(data.toString())
	})
	return childProcessToPromise(child)
}

/**
 * Copy the config file to the playground source dir, with a correct env mode.
 *
 * @returns {Promise<void>}
 */
async function buildConfig() {
	const content = await fsp.readFile(config_path, "utf8")
	const corrected = correctConfigMode(content)
	await fsp.writeFile(config_out_path, corrected)
}

/** @returns {string} */
function correctConfigMode(/** @type {string} */ env) {
	return "export const IS_DEV = /** @type {boolean} */ (true)\n" + shiftLines(env, 1)
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

/** @returns {string} */
function toWebFilepath(/** @type {string} */ path) {
	return path.endsWith("/") ? path + "index.html" : path
}

/** @returns {Promise<boolean>} */
function fileExists(/** @type {string} */ filepath) {
	return unsafePromiseToBool(fsp.access(filepath))
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
