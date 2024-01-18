# Odin WASM

For using Odin and WASM together.

## Development

### Requirements

-   [LLVM 14](https://apt.llvm.org/) - `llvm-17` can generte wrong wasm ([issue](https://github.com/odin-lang/Odin/issues/2855))
-   [Odin](https://odin-lang.org/docs/install/)
-   [Node 20](https://nodejs.org/)
-   [PNPM](https://pnpm.io/installation) _(`npm` and others will also work, just don't commit the lockfile)_

### OLS

Add `js_wasm32` target to `ols.json`:

```json
{
	"checker_args": "-target:js_wasm32 -vet-unused -vet-shadowing -vet-style -vet-semicolon"
}
```
