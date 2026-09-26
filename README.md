## SynOS kernel

The SynOS kernel is a security-first operating system designed to protect private files, databases, services, and user workloads through operating-system-enforced security.

### Architecture
SynOS instead uses a **microkernel architecture**: drivers, filesystems, and network stacks run as isolated, unprivileged user-space servers, each in its own address space. Compromising one component does not hand an attacker the rest of the machine.

### Artificial Intelligence
SynOS is absolutely AGAINST vibe coding. Every line of kernel code in this repository must be written by a human. See [`CONTRIBUTING.md`] (CONTRIBUTING.md) for the project's policy on AI-assisted contributions.

### License
SynOS is a free and open-source software, licensed under the GNU General Public License. See [`LICENSE`] (LICENSE) for all license details.
