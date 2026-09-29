## SynOS Kernel

SynOS is a security-first operating system kernel designed to protect private files, databases, services, and user workloads through operating-system-enforced security.

### Project Status
SynOS is in a very early stage of development. The initial target architecture is **x86_64**. There is no kernel yet; work so far covers the first stage of booting:

- A 512-byte boot sector that sets up a known real-mode execution environment (segment registers, stack, and the boot drive number passed by the BIOS) and prints a status message.
- Loading a two-sector loader from the boot disk into memory with BIOS disk services (`int 0x13`) and handing control to it, passing the boot drive number; an error is printed if the read fails.
- A loader that prints a message stored in its second sector, confirming that both sectors were loaded.
- A build script (`scripts/build.sh`) that assembles the boot sector and loader with NASM and joins them into a bootable raw disk image, `boot/synos.img`.

### Getting Started
Building SynOS requires four tools:

- [Git](https://git-scm.com/): downloads the source code
- [NASM](https://www.nasm.us/): assembles the boot sector source
- [QEMU](https://www.qemu.org/): emulates an x86 machine and boots the disk image
- Bash: runs the build script

#### macOS
Install [Homebrew](https://brew.sh/) (the macOS package manager) if it is not already installed:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

When the installer finishes, follow the **Next steps** it prints. On Apple Silicon Macs these add Homebrew to your `PATH`, usually:

```sh
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Install the tools:

```sh
brew install git nasm qemu
```

Verify the installation:

```sh
git --version
nasm -v
qemu-system-x86_64 --version
```

#### Debian / Ubuntu
```sh
sudo apt update
sudo apt install -y git nasm qemu-system-x86
```

Verify the installation:

```sh
git --version
nasm -v
qemu-system-x86_64 --version
```

#### Fedora
```sh
sudo dnf install -y git nasm qemu-system-x86
```

Verify the installation:

```sh
git --version
nasm -v
qemu-system-x86_64 --version
```

#### Arch Linux
```sh
sudo pacman -S --needed git nasm qemu-system-x86
```

Verify the installation:

```sh
git --version
nasm -v
qemu-system-x86_64 --version
```

#### Windows
SynOS builds on Windows through [WSL](https://learn.microsoft.com/windows/wsl/) (Windows Subsystem for Linux), which runs Ubuntu inside Windows.

1. Open **PowerShell as Administrator** and run:
   ```powershell
   wsl --install
   ```
2. Restart Windows if prompted.
3. Open the **Ubuntu** app from the Start menu and complete its first-run username and password setup.
4. Follow the **Debian / Ubuntu** instructions above, and run every remaining command inside the Ubuntu terminal.

WSL requires hardware virtualization, which is enabled by default on most modern PCs but may need to be turned on in the UEFI/BIOS settings. The QEMU window appears through WSL's built-in graphical app support, available on Windows 11 and recent versions of Windows 10.

#### Clone, build, and run
```sh
git clone https://github.com/lakvijayaku/SynOS.git
cd SynOS
bash scripts/build.sh
qemu-system-x86_64 -drive format=raw,file=boot/synos.img -no-reboot
```

A QEMU window opens showing the boot sector's status message, followed by the loader's message. To quit, close the QEMU window, or press `Ctrl+C` in the terminal that started it.

### Architecture
SynOS uses a **microkernel architecture**: drivers, filesystems, and network stacks run as isolated, unprivileged user-space servers, each in its own address space. Compromising one component does not give an attacker control of the rest of the machine.

### AI-Assisted Development
SynOS does not accept "vibe-coded" contributions. All code in this repository must be written by a human, and every commit must be made by a human. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full policy.

### Contact
Questions, bug reports, and suggestions can be sent to the project owner at lakvijayaku@gmail.com.

### License
SynOS is free and open-source software, licensed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE) for details.
