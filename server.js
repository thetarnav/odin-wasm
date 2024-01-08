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
	HTTP_PORT,
	MESSAGE_RELOAD,
	PACKAGE_DIRNAME,
	PLAYGROUND_DIRNAME,
	WASM_FILENAME,
	WASM_PATH,
	WEB_SOCKET_PORT,
} from "./constants.js"

const dirname = path.dirname(url.fileURLToPath(import.meta.url))
const playground_path = path.join(dirname, PLAYGROUND_DIRNAME)
const dist_path = path.join(dirname, DIST_DIRNAME)
const package_path = path.join(dirname, PACKAGE_DIRNAME)

/* Make sure the dist dir exists */
void fs.mkdirSync(dist_path, {recursive: true})

const server = http.createServer(requestListener).listen(HTTP_PORT)
const wss = new ws.WebSocketServer({port: WEB_SOCKET_PORT})

// eslint-disable-next-line no-console
console.log(`
Server running at http://127.0.0.1:${HTTP_PORT}
WebSocket server running at http://127.0.0.1:${WEB_SOCKET_PORT}
`)

const watcher = chokidar.watch(
	[
		`./${PLAYGROUND_DIRNAME}/**/*.{js,html,odin}`,
		`./${PACKAGE_DIRNAME}/**/*.{js,odin}`,
		"./*.js",
	],
	{
		// ignore dotfiles and tests (.test.js)
		ignored: [/(^|[\/\\])\../, /\.test\.js$/],
		ignoreInitial: true,
	},
)
void watcher.on("change", handleFileChange)

/** @type {Promise<number>} */
let wasm_build_promise = buildWASM()

/** @returns {Promise<void>} */
async function requestListener(
	/** @type {http.IncomingMessage} */ req,
	/** @type {http.ServerResponse} */ res,
) {
	if (!req.url || req.method !== "GET") {
		void res.writeHead(404)
		void res.end()
		// eslint-disable-next-line no-console
		console.log(`${req.method} ${req.url} 404`)
		return
	}

	if (req.url === WASM_PATH) {
		await wasm_build_promise
	} else if (req.url === "/" || req.url === "/index.html") {
		req.url = "/" + PLAYGROUND_DIRNAME + "/index.html"
	}

	/*
	Static files
	*/
	const relative_filepath = toWebFilepath(req.url)
	const filepath = path.join(dirname, relative_filepath)

	const exists = await fileExists(filepath)
	if (!exists) {
		void res.writeHead(404)
		void res.end()
		// eslint-disable-next-line no-console
		console.log(`${req.method} ${req.url} 404`)
		return
	}

	const ext = toExt(filepath)
	const mime_type = mimeType(ext)
	void res.writeHead(200, {"Content-Type": mime_type})

	const stream = fs.createReadStream(filepath)
	void stream.pipe(res)

	// eslint-disable-next-line no-console
	console.log(`${req.method} ${req.url} 200`)
}

/** @typedef {Parameters<ws.WebSocket["send"]>[0]} BufferLike */

/** @returns {void} */
function sendToAllClients(/** @type {BufferLike} */ data) {
	for (const client of wss.clients) {
		client.send(data)
	}
}

/** @returns {void} */
function handleFileChange(/** @type {string} */ filepath) {
	// Rebuild the WASM
	if (filepath.endsWith(".odin")) {
		// eslint-disable-next-line no-console
		console.log("Rebuilding WASM...")
		wasm_build_promise = buildWASM()
		sendToAllClients(MESSAGE_RELOAD)
	}
	// Reload the page
	else if (filepath.startsWith(PLAYGROUND_DIRNAME) || filepath.startsWith(PACKAGE_DIRNAME)) {
		// eslint-disable-next-line no-console
		console.log("Reloading page...")
		sendToAllClients(MESSAGE_RELOAD)
	}
	// Restart the server
	else {
		// eslint-disable-next-line no-console
		console.log("Restarting server...")
		sendToAllClients(MESSAGE_RELOAD)
		void server.close()
		wss.close()
		void process.exit(0)
		return
	}
}

/** @returns {Promise<number>} */
async function buildWASM() {
	const build_cmd = `odin build ${playground_path} -out:${DIST_DIRNAME}/${WASM_FILENAME} -target:js_wasm32`
	const child = await child_process.exec(build_cmd, {cwd: dirname})
	return childProcessToPromise(child)
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
