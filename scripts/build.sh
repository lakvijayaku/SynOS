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

current_step="compiling data sector"
echo "🔨 Compiling data sector..."
nasm -f bin -Werror boot/data_sector.asm -o boot/data_sector.bin

current_step="checking sector sizes"
for f in boot/boot_sector.bin boot/data_sector.bin; do
    size=$(wc -c < "$f" | tr -d ' ')
    if [ "$size" -ne 512 ]; then
        echo "${RED}$f is $size bytes; every sector must be exactly 512${RESET}"
        false
    fi
done

current_step="combining sectors into disk image"
echo "📦 Combining sectors into raw disk image..."
cat boot/boot_sector.bin boot/data_sector.bin > boot/synos.img

echo "${GREEN}✅ Success! Output created at boot/synos.img${RESET}"
