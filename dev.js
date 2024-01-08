import * as child_process from "node:child_process"

/** @type {child_process.ChildProcess} */
let child

startServer()

function startServer() {
	child = child_process.spawn("node", ["server.js"], {
		stdio: "inherit",
		shell: true,
	})

	void child.on("close", code => {
		if (code === 0) {
			startServer()
		}
	})
}
