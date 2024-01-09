import * as child_process from "node:child_process"
import * as chokidar from "chokidar"

/** @type {child_process.ChildProcess} */
let child = makeChildServer()

const watcher = chokidar.watch(["./*.js"], {
	// ignore dotfiles
	ignored: /(^|[\/\\])\../,
	ignoreInitial: true,
})
void watcher.on("change", restartServer)

/** @returns {child_process.ChildProcess} */
function makeChildServer() {
	return child_process.spawn("node", ["server.js"], {stdio: "inherit"})
}

/** @returns {void} */
function restartServer() {
	// eslint-disable-next-line no-console
	console.log("Stopping server...")
	const ok = child.kill("SIGINT")
	if (!ok) {
		// eslint-disable-next-line no-console
		console.log("Failed to kill server")
		return
	}

	child = makeChildServer()
}
