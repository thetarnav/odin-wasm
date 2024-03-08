# Script to setup Odin and LLVM 14 on GitHub Actions

ODIN_RELEASE_ID=dev-2024-03

echo "Setting up LLVM 14 and Odin ${ODIN_RELEASE_ID}..."

wget -O odin.zip -q https://github.com/odin-lang/Odin/releases/download/${ODIN_RELEASE_ID}/odin-ubuntu-amd64-${ODIN_RELEASE_ID}.zip
unzip odin.zip
unzip dist.zip
cp -r dist/* /home/runner/odin

echo "/home/runner/odin" >>$GITHUB_PATH
echo "/usr/lib/llvm-14/bin" >>$GITHUB_PATH
export PATH="/home/runner/odin:$PATH"
export PATH="/usr/lib/llvm-14/bin:$PATH"

echo "Done!"
echo "llvm:    $(llvm-config --version)"
echo "wasm-ld: $(wasm-ld --version)"
echo "odin:    $(odin version)"

if ! command -v llvm-config &> /dev/null
then
	echo "llvm-config could not be found"
	exit 1
fi

if ! command -v wasm-ld &> /dev/null
then
	echo "wasm-ld could not be found"
	exit 1
fi

if ! command -v odin &> /dev/null
then
	echo "odin could not be found"
	exit 1
fi