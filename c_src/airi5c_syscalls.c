/*
 * airi5c_syscalls.c
 *
 *  Created on: 11.11.2019
 *      Author: stanitzk
 *
 *  This is a non-reentrant implementation of the 13 syscalls required by
 *  newlib.
 */

#include <sys/stat.h>
#include <errno.h>
#include "airi5c_syscalls.h"

#undef errno
extern int errno;	// linker script defines address for this


char *__env[1] = { 0 };
char **environ = __env;

void _exit(int i) {
	while(1);		// park loop
}

int _close(int file) {
	return(-1);		// the only file is stdout, which cannot be closed
}

int _execve(char *name, char **argv, char **env) {
	errno = ENOMEM;
	return -1;
}


int _fork() {
	errno = EAGAIN;
	return(-1);
}

int _fstat(int file, struct stat *st) {
	st->st_mode = S_IFCHR;
	return 0;
}

int _getpid(void) {
	return 1;
}

int _isatty(int file) {
	return 1;
}

int _kill(int pid, int sig) {
	errno = EINVAL;
	return -1;
}

int _link(char *old, char *new) {
	errno = EMLINK;
	return -1;
}

int _lseek(int file, int ptr, int dir) {
	return 0;
}

int _open(const char *name, int flags, ...) {
	return -1;
}

int _read(int file, char *ptr, int len) {
	return 0;
}

caddr_t _sbrk(int incr) {
	extern int __end;
	static void *heap_end;
	void *prev_heap_end;

	register void* stack_ptr asm("sp");
	if(heap_end == NULL)
		heap_end = (void*)&__end;
	prev_heap_end = heap_end;
	if((void*)(heap_end + incr) > stack_ptr) {
		write(1, "Heap and stack collision\n",25);
		while(1);
	}
	heap_end += incr;
	return (caddr_t) prev_heap_end;
}

int _stat(const char *file, struct stat *st) {
	st->st_mode = S_IFCHR;
	return 0;
}

clock_t _times(struct tms *buf) {
	errno = EACCES;
	return -1;
}
int _unlink(char *name) {
	errno = ENOENT;
	return -1;
}

int _wait(int *status) {
	errno = ECHILD;
	return -1;
}

void outbyte(char payload)
{
	int i;
	volatile extern int _uart_dreg;
	_uart_dreg = 0x100 | payload;
	_uart_dreg = 0x000;
	for(i = 0; i < 10000; i++);
}

int _write(int file, char *ptr, int len) {
	int i;
	for(i = 0; i < len; i++)
	{
		outbyte(ptr[i]);
	}
	return len;
}


