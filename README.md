# x86 Assembly System Monitor

A lightweight system resource monitor written in pure x86-64 assembly language for Linux. This tool displays real-time memory and CPU usage statistics by directly interfacing with Linux system calls and the `/proc` filesystem.

## Features

- **Memory Usage Monitoring**
  - Total system memory
  - Free memory
  - Used memory calculation
  - Values displayed in KB

- **CPU Usage Monitoring**
  - Real-time CPU activity percentage
  - Reads directly from `/proc/stat`
  - Calculates active vs idle time

- **Pure Assembly Implementation**
  - No external libraries or dependencies
  - Direct system calls for maximum performance
  - Minimal memory footprint (~4KB buffer)

## Prerequisites

- **Assembler**: NASM (Netwide Assembler)
- **Architecture**: x86-64 (64-bit)
- **Operating System**: Linux
- **Linker**: ld (GNU linker)

### Installation on Linux

```bash
# Debian/Ubuntu
sudo apt-get install nasm

# Arch Linux
sudo pacman -S nasm

# Fedora/RHEL
sudo dnf install nasm
```

## Building the Project

### Compile and Link

```bash

# Assemble the source code
nasm -f elf64 monitor.asm -o monitor.o

# Link the object file
ld -o monitor monitor.o

# Make executable (if needed)
chmod +x monitor
```

### One-line Build

```bash
nasm -f elf64 monitor.asm -o monitor.o && ld -o monitor monitor.o
```

## Usage

Simply run the compiled binary:

```bash
./monitor
```

### Sample Output

```
=== Memory Usage ===
Total Memory: 16384000 KB
Free Memory: 8192000 KB
Used Memory: 8192000 KB

=== CPU Usage ===
CPU Active: 35%
```

## How It Works

### Memory Monitoring

The program uses the `sysinfo` system call (syscall number 99) to retrieve system memory information:

- **System Call**: `sys_sysinfo`
- **Data Structure**: 112-byte sysinfo struct
- **Fields Used**:
  - `totalram` (offset 8): Total usable RAM
  - `freeram` (offset 16): Available RAM
- **Calculation**: `used_memory = totalram - freeram`

### CPU Monitoring

CPU statistics are obtained by reading and parsing `/proc/stat`:

1. **Open** `/proc/stat` using `sys_open` (syscall 2)
2. **Read** the first line containing CPU time values (syscall 0)
3. **Parse** the values: `cpu user nice system idle iowait...`
4. **Calculate** CPU usage percentage:
   ```
   active_time = user + nice + system
   total_time = active_time + idle
   cpu_usage = (active_time * 100) / total_time
   ```
5. **Close** the file using `sys_close` (syscall 3)

### System Calls Used

| Syscall Number | Name | Purpose |
|----------------|------|---------|
| 0 | sys_read | Read from file descriptor |
| 1 | sys_write | Write to stdout |
| 2 | sys_open | Open `/proc/stat` |
| 3 | sys_close | Close file descriptor |
| 60 | sys_exit | Exit program |
| 99 | sys_sysinfo | Get system information |

## Technical Details

### File Structure

```
monitor.asm
├── .data section    # Static strings and file paths
├── .bss section     # Uninitialized buffers
└── .text section    # Code and functions
    ├── _start       # Entry point
    ├── print_number # Convert and display numbers
    ├── parse_cpu_stats # Parse /proc/stat
    ├── read_number  # Parse ASCII to integer
    └── print_cpu_usage # Display CPU percentage
```

### Memory Layout

- **sysinfo_buffer**: 112 bytes for system info struct
- **file_buffer**: 4096 bytes for reading `/proc/stat`
- **num_buffer**: 20 bytes for number-to-string conversion

### Assembly Syntax

- **Format**: NASM (Intel syntax)
- **Target**: ELF64 (64-bit Linux executable)
- **Registers**: Uses 64-bit registers (rax, rbx, rcx, etc.)

## Code Highlights

### Direct System Call Interface

```nasm
mov rax, 99             ; sys_sysinfo syscall
mov rdi, sysinfo_buffer ; pointer to buffer
syscall                 ; execute system call
```

### Number Conversion Algorithm

The program includes a custom integer-to-ASCII conversion routine:
- Divides by 10 repeatedly
- Converts remainders to ASCII characters
- Builds string in reverse order

### File I/O Without Libraries

All file operations are performed using raw system calls:
- No libc or standard library
- Direct kernel interface
- Maximum efficiency

## Performance

- **Startup Time**: < 1ms
- **Memory Usage**: ~112 bytes + 4KB buffers
- **Binary Size**: ~2-3 KB (after linking)
- **CPU Overhead**: Negligible (single snapshot read)

## Limitations

- **Platform**: Linux x86-64 only
- **Accuracy**: CPU usage is a single-point snapshot (not averaged over time)
- **Display**: Text-only output
- **Real-time**: No continuous monitoring (runs once and exits)

## Extending the Project

### Add Continuous Monitoring

Wrap the main logic in a loop with sleep delays:

```nasm
; Add sys_nanosleep syscall to pause between updates
; Loop back to monitoring code
```

### Monitor Additional Resources

- **Network**: Parse `/proc/net/dev`
- **Disk I/O**: Read `/proc/diskstats`
- **Processes**: Count entries in `/proc`
- **Uptime**: Use data from sysinfo struct

### Enhanced Output

- Add ANSI color codes for visual formatting
- Create progress bars using ASCII characters
- Display values in MB/GB for larger systems

## Learning Resources

- [Linux System Call Table](https://filippo.io/linux-syscall-table/)
- [x86-64 Assembly Guide](https://cs.lmu.edu/~ray/notes/x86assembly/)
- [NASM Documentation](https://www.nasm.us/docs.php)
- [Linux /proc Filesystem](https://www.kernel.org/doc/Documentation/filesystems/proc.txt)
- [OSDev Wiki - x86](https://wiki.osdev.org/X86-64)

## Troubleshooting

### "Permission denied" error
```bash
chmod +x monitor
```

### "Segmentation fault"
- Ensure you're running on a 64-bit Linux system
- Check that NASM version supports ELF64 format

### Numbers not displaying correctly
- Verify buffer sizes in `.bss` section
- Check for integer overflow on systems with >2TB RAM

## License

This project is open source and available for educational purposes. Feel free to modify and distribute.

## Contributing

Contributions are welcome! Areas for improvement:
- Cross-platform support (BSD, macOS)
- Real-time continuous monitoring
- Better error handling
- More system metrics

## Author

Created as an educational project to demonstrate low-level system programming and direct kernel interaction using x86-64 assembly language.

## Acknowledgments

- Linux kernel documentation
- NASM community
- x86-64 assembly learning resources

---

**Happy Assembly Coding! 🚀**
