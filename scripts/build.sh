#!/bin/bash
#
# Build the SynOS disk image: assemble each sector, then join them into
# boot/synos.img. Run from anywhere: ./scripts/build.sh

# Stop at the first failing command; -o pipefail also catches failures inside pipes
set -eo pipefail

# Always run from the repository root, so the relative paths below work
cd "$(dirname "$0")/.."

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
RESET=$'\033[0m'

# On any failure, say which step failed before exiting
current_step=""
trap 'echo; echo "${RED}❌ Build failed while: ${current_step}${RESET}"; echo "${RED}   Read the FIRST error above; later errors are often caused by it.${RESET}"' ERR

current_step="compiling boot sector"
echo "🔨 Compiling boot sector..."
nasm -f bin -Werror boot/boot_sector.asm -o boot/boot_sector.bin

current_step="compiling loader"
echo "🔨 Compiling loader..."
nasm -f bin -Werror boot/loader.asm -o boot/loader.bin

current_step="checking sector sizes"
for f in boot/boot_sector.bin boot/loader.bin; do
    size=$(wc -c < "$f" | tr -d ' ')
    # Check if the size modulo 512 is NOT equal to 0
    if [ $((size % 512)) -ne 0 ]; then
        echo "${RED}$f is $size bytes; every file must be a multiple of 512 bytes${RESET}"
        false
    fi
done

current_step="combining sectors into disk image"
echo "📦 Combining sectors into raw disk image..."
cat boot/boot_sector.bin boot/loader.bin > boot/synos.img

echo "${GREEN}✅ Success! Output created at boot/synos.img${RESET}"
