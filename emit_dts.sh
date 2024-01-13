# Emits d.ts files from the wasm package
# For use in a typescript project.
# .d.ts files that are in the wasm package are linked from the types folder
# Thats because tsc doesn't emits them emtpy for some reason

rm -rf types
mkdir types
pnpm tsc -p ./jsconfig.build.json
cd wasm
find . -name "*.d.ts" -exec ln -srf "{}" "../types/{}" \;
# find . -name "*.d.ts" -exec bash -c 'ln -srf "{}" "../types/{}"; rm "../types/{}.map"' \;
