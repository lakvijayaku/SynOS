## SynOS Kernel

SynOS is a security-first operating system kernel designed to protect private files, databases, services, and user workloads through operating-system-enforced security.

### Project Status
SynOS is in a very early stage of development. The repository currently contains no kernel code, only project documentation. The initial target architecture is **x86_64**.

### Architecture
SynOS uses a **microkernel architecture**: drivers, filesystems, and network stacks run as isolated, unprivileged user-space servers, each in its own address space. Compromising one component does not give an attacker control of the rest of the machine.

### AI-Assisted Development
SynOS does not accept "vibe-coded" contributions. All code in this repository must be written by a human, and every commit must be made by a human. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full policy.

### Contact
Questions, bug reports, and suggestions can be sent to the project owner at lakvijayaku@gmail.com.

### License
SynOS is free and open-source software, licensed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE) for details.
