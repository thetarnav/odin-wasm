import * as url from "node:url"
import * as fs from "node:fs"
import * as fsp from "node:fs/promises"
import * as http from "node:http"
import * as path from "node:path"
import * as chokidar from "chokidar"
import * as ws from "ws"

import {
	HTTP_PORT,
	WEB_SOCKET_PORT,
	THEME_JSONC_FILENAME,
	CODE_FILENAME,
	LANG_FILENAME,
	THEME_JSON_WEBPATH,
	CODE_WEBPATH,
	LANG_WEBPATH,
} from "./constants.js"

const dirname = path.dirname(url.fileURLToPath(import.meta.url))
const src_path = path.join(dirname, "src")
const theme_jsonc_path = path.join(src_path, THEME_JSONC_FILENAME)
const code_path = path.join(src_path, CODE_FILENAME)
const lang_path = path.join(src_path, LANG_FILENAME)

http.createServer(requestListener).listen(HTTP_PORT)
// eslint-disable-next-line no-console
console.log(`Server running at http://127.0.0.1:${HTTP_PORT}`)

const wss = new ws.WebSocketServer({port: WEB_SOCKET_PORT})
// eslint-disable-next-line no-console
console.log("WebSocket server running at http://127.0.0.1:" + WEB_SOCKET_PORT)

/** @type {Promise<string>} */
let last_theme_json = buildTheme()

chokidar.watch([theme_jsonc_path, code_path, lang_path]).on("change", handleFileChange)

/**
 * @param   {http.IncomingMessage} req
 * @param   {http.ServerResponse}  res
 * @returns {Promise<void>}
 */
async function requestListener(req, res) {
	if (!req.url || req.method !== "GET") {
		res.writeHead(404)
		res.end()
		// eslint-disable-next-line no-console
		console.log(`${req.method} ${req.url} 404`)
		return
	}

	/*
	Generated files
	*/
	if (req.url === THEME_JSON_WEBPATH) {
		const theme_json = await last_theme_json
		res.writeHead(200, {"Content-Type": "application/json"})
		res.end(theme_json)
		// eslint-disable-next-line no-console
		console.log(`${req.method} ${req.url} 200`)
		return
	}

	/*
	Static files
	*/
	const relative_filepath = toWebFilepath(req.url)
	const filepath = relative_filepath.startsWith("/node_modules/")
		? path.join(dirname, relative_filepath)
		: path.join(src_path, relative_filepath)

	const exists = await fileExists(filepath)
	if (!exists) {
		res.writeHead(404)
		res.end()
		// eslint-disable-next-line no-console
		console.log(`${req.method} ${req.url} 404`)
		return
	}

	const ext = toExt(filepath)
	const mime_type = mimeType(ext)
	res.writeHead(200, {"Content-Type": mime_type})

	const stream = fs.createReadStream(filepath)
	stream.pipe(res)

	// eslint-disable-next-line no-console
	console.log(`${req.method} ${req.url} 200`)
}

/**
 * @param   {string} path
 * @returns {void}
 */
function notifyClients(path) {
	// eslint-disable-next-line no-console
	console.log(path, "changed!")

	for (const client of wss.clients) {
		client.send(path)
	}
}

/**
 * @param   {string} path
 * @returns {void}
 */
function handleFileChange(path) {
	switch (path) {
		case theme_jsonc_path: {
			last_theme_json = buildTheme()
			notifyClients(THEME_JSON_WEBPATH)
			break
		}
		case code_path: {
			notifyClients(CODE_WEBPATH)
			break
		}
		case lang_path: {
			notifyClients(LANG_WEBPATH)
			break
		}
	}
}

/** @returns {Promise<string>} */
async function buildTheme() {
	const theme_jsonc = await fsp.readFile(theme_jsonc_path, "utf8")
	const theme = jsonc.parse(theme_jsonc)
	return JSON.stringify(theme, null, 4)
}

/**
 * @param   {string} ext
 * @returns {string}
 */
function mimeType(ext) {
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
 * @param   {Promise<any>}     promise
 * @returns {Promise<boolean>}
 */
function promiseToBool(promise) {
	return promise.then(trueFn, falseFn)
}

/**
 * @param   {string} path
 * @returns {string}
 */
function toWebFilepath(path) {
	return path.endsWith("/") ? path + "index.html" : path
}

/**
 * @param   {string}           filepath
 * @returns {Promise<boolean>}
 */
function fileExists(filepath) {
	return promiseToBool(fsp.access(filepath))
}

/**
 * @param   {string} filepath
 * @returns {string}
 */
function toExt(filepath) {
	return path.extname(filepath).substring(1).toLowerCase()
}
