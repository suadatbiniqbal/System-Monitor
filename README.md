# x86 Assembly System Monitor

A small system monitor written in x86-64 assembly for Linux.  
It shows basic CPU and memory usage by reading system data directly.

## What it does

- Shows total, free, and used memory  
- Shows CPU usage percentage  
- Reads data from `/proc` and system calls  
- No libraries, just pure assembly  

## Requirements

- Linux (64-bit)
- NASM
- ld (linker)

Install NASM:

```bash
# Ubuntu / Debian
sudo apt install nasm

# Arch
sudo pacman -S nasm

# Fedora
sudo dnf install nasm
```

## Build

```bash
nasm -f elf64 monitor.asm -o monitor.o
ld -o monitor monitor.o
chmod +x monitor
```

Or in one line:

```bash
nasm -f elf64 monitor.asm -o monitor.o && ld -o monitor monitor.o
```

## Run

```bash
./monitor
```

Example output:

```
Memory:
Total: 16384000 KB
Free: 8192000 KB
Used: 8192000 KB

CPU:
Usage: 35%
```

## How it works (simple)

- Memory → uses `sysinfo` syscall  
- CPU → reads `/proc/stat`  
- Calculates usage from active vs idle time  

## Notes

- Runs once and exits (not live updating)
- Linux only
- Very small and fast

## If you want to improve it

- Add a loop for live monitoring  
- Add colors or better formatting  
- Show more stats (disk, network, etc.)

## Why this exists

Just a simple project to understand:
- assembly basics  
- Linux syscalls  
- how the system actually works under the hood  
