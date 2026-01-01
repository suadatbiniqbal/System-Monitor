; Memory and CPU Monitor for x86-64 Linux
; Assemble: nasm -f elf64 monitor.asm
; Link: ld -o monitor monitor.asm

section .data
    ; Messages
    mem_msg db "=== Memory Usage ===", 10, 0
    mem_msg_len equ $ - mem_msg
    
    total_msg db "Total Memory: ", 0
    total_msg_len equ $ - total_msg
    
    free_msg db "Free Memory: ", 0
    free_msg_len equ $ - free_msg
    
    used_msg db "Used Memory: ", 0
    used_msg_len equ $ - used_msg
    
    cpu_msg db 10, "=== CPU Usage ===", 10, 0
    cpu_msg_len equ $ - cpu_msg
    
    proc_stat db "/proc/stat", 0
    proc_meminfo db "/proc/meminfo", 0
    
    kb_suffix db " KB", 10, 0
    kb_suffix_len equ $ - kb_suffix
    
    newline db 10, 0

section .bss
    sysinfo_buffer resb 112    ; sysinfo struct buffer
    file_buffer resb 4096      ; buffer for reading /proc files
    num_buffer resb 20         ; buffer for number conversion

section .text
    global _start

_start:
    ; Print Memory header
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, mem_msg
    mov rdx, mem_msg_len
    syscall
    
    ; Get memory info using sysinfo syscall
    mov rax, 99             ; sys_sysinfo syscall number
    mov rdi, sysinfo_buffer ; pointer to buffer
    syscall
    
    ; Print Total Memory
    mov rax, 1
    mov rdi, 1
    mov rsi, total_msg
    mov rdx, total_msg_len
    syscall
    
    ; Get totalram (offset 8 in sysinfo struct)
    mov rax, [sysinfo_buffer + 8]
    mov rbx, 1024           ; Convert bytes to KB
    xor rdx, rdx
    div rbx
    call print_number
    
    ; Print Free Memory
    mov rax, 1
    mov rdi, 1
    mov rsi, free_msg
    mov rdx, free_msg_len
    syscall
    
    ; Get freeram (offset 16 in sysinfo struct)
    mov rax, [sysinfo_buffer + 16]
    mov rbx, 1024
    xor rdx, rdx
    div rbx
    call print_number
    
    ; Print Used Memory
    mov rax, 1
    mov rdi, 1
    mov rsi, used_msg
    mov rdx, used_msg_len
    syscall
    
    ; Calculate used = total - free
    mov rax, [sysinfo_buffer + 8]   ; total
    mov rbx, [sysinfo_buffer + 16]  ; free
    sub rax, rbx                     ; used = total - free
    mov rbx, 1024
    xor rdx, rdx
    div rbx
    call print_number
    
    ; Print CPU header
    mov rax, 1
    mov rdi, 1
    mov rsi, cpu_msg
    mov rdx, cpu_msg_len
    syscall
    
    ; Open /proc/stat
    mov rax, 2              ; sys_open
    mov rdi, proc_stat
    mov rsi, 0              ; O_RDONLY
    syscall
    
    test rax, rax
    js exit                 ; Jump if error
    mov r15, rax            ; Save file descriptor
    
    ; Read /proc/stat
    mov rax, 0              ; sys_read
    mov rdi, r15            ; file descriptor
    mov rsi, file_buffer
    mov rdx, 4096
    syscall
    
    ; Close file
    mov rax, 3              ; sys_close
    mov rdi, r15
    syscall
    
    ; Parse CPU line (first line: "cpu user nice system idle...")
    call parse_cpu_stats
    
exit:
    ; Exit program
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; exit code 0
    syscall

; Print number in RAX
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rbx, 10
    mov rcx, 0
    mov rsi, num_buffer
    add rsi, 19             ; Point to end of buffer
    
.convert_loop:
    xor rdx, rdx
    div rbx                 ; RAX / 10
    add dl, '0'             ; Convert remainder to ASCII
    dec rsi
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .convert_loop
    
    ; Print the number
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rdx, rcx            ; length
    syscall
    
    ; Print KB suffix
    mov rax, 1
    mov rdi, 1
    mov rsi, kb_suffix
    mov rdx, kb_suffix_len
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Parse CPU statistics from /proc/stat
parse_cpu_stats:
    push rbx
    push rcx
    
    ; Skip "cpu " prefix (4 bytes)
    mov rsi, file_buffer
    add rsi, 4
    
    ; Read first number (user time)
    call read_number
    mov rbx, rax            ; Save user time
    
    ; Read second number (nice time)
    call read_number
    add rbx, rax            ; Add to total
    
    ; Read third number (system time)
    call read_number
    add rbx, rax
    
    ; Read fourth number (idle time)
    call read_number
    mov rcx, rax            ; Save idle time
    
    ; Calculate usage percentage (simplified)
    ; usage = (total - idle) * 100 / total
    mov rax, rbx
    sub rax, rcx            ; active = total - idle
    mov rdx, 100
    mul rdx                 ; active * 100
    div rbx                 ; / total
    
    ; Print CPU usage
    call print_cpu_usage
    
    pop rcx
    pop rbx
    ret

; Read a number from [RSI], advance RSI
read_number:
    push rbx
    xor rax, rax
    xor rbx, rbx
    
.read_loop:
    mov bl, [rsi]
    inc rsi
    
    cmp bl, ' '
    je .done
    cmp bl, 10              ; newline
    je .done
    cmp bl, 0
    je .done
    
    sub bl, '0'
    imul rax, 10
    add rax, rbx
    jmp .read_loop
    
.done:
    pop rbx
    ret

; Print CPU usage percentage
print_cpu_usage:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Print "CPU Active: "
    mov r8, rax             ; Save percentage
    
    mov rax, 1
    mov rdi, 1
    mov rsi, cpu_active_msg
    mov rdx, cpu_active_len
    syscall
    
    ; Print percentage
    mov rax, r8
    call print_number_no_kb
    
    ; Print "%\n"
    mov rax, 1
    mov rdi, 1
    mov rsi, percent_msg
    mov rdx, 2
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Print number without KB suffix
print_number_no_kb:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rbx, 10
    mov rcx, 0
    mov rsi, num_buffer
    add rsi, 19
    
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .convert
    
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

section .data
    cpu_active_msg db "CPU Active: ", 0
    cpu_active_len equ $ - cpu_active_msg
    percent_msg db "%", 10
