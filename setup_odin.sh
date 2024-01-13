ODIN_RELEASE_ID=dev-2024-01

echo "Setting up LLVM 14 and Odin ${ODIN_RELEASE_ID}..."

wget -O odin.zip -q https://github.com/odin-lang/Odin/releases/download/${ODIN_RELEASE_ID}/odin-ubuntu-amd64-${ODIN_RELEASE_ID}.zip
unzip odin.zip -d /home/runner/odin
chmod +x /home/runner/odin/odin

echo "/home/runner/odin" >>$GITHUB_PATH
echo "/usr/lib/llvm-14/bin" >>$GITHUB_PATH
export PATH="/home/runner/odin:$PATH"
export PATH="/usr/lib/llvm-14/bin:$PATH"

echo "Done!"
echo "llvm:    $(llvm-config --version)"
echo "wasm-ld: $(wasm-ld --version)"
echo "odin:    $(odin version)"
