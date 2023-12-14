/*
 ============================================================================
 Name        : main.c
 Author      : F. Bruenger
 Version     :
 Copyright   : 
 Description : POMAA Final Code. Reading caeco information
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "airi5c_syscalls.h"
// globals
int *cur_res = NULL;	// saves the current result = pointer
int *out_res = NULL;
int *storage = NULL;


void exception_handler(void) __attribute((interrupt));
void exception_handler(void){
	// do nothing
}

void l_1_caeco_interrupt_handler(void) __attribute((interrupt));
void l_1_caeco_interrupt_handler(void){
	// getting the caeco address
	int* pointer = (int *) 0xc0000012;
	// read from the caeco address
	int value = *pointer;
	// write the result to the first pointer
	*cur_res = value;
	// increment the address of the storage
	++cur_res;
}

int main (void)
{

	register int* gpio_addr_w = (int *) 0xc0000008;
	register int* gpio_addr_r = (int *) 0xc0000008;
	char r_val_1;	// using char for byte size
	char r_val_2;
	char r_val_3;
	char r_val_4;
	register int w_val_1 = 0x01;
	register int w_val_2 = 0x02;
	register int w_val_3 = 0x04;
	register int w_val_4 = 0x08;

	*gpio_addr_w = *gpio_addr_r;
	*gpio_addr_w = *gpio_addr_r;
	*gpio_addr_w = *gpio_addr_r;
	*gpio_addr_w = *gpio_addr_r;

/*
	*gpio_addr = w_val_1;
	r_val_1 = *gpio_addr;
	*gpio_addr = w_val_2;
	r_val_2 = *gpio_addr;
	*gpio_addr = w_val_3;
	r_val_3 = *gpio_addr;
	*gpio_addr = w_val_4;
	r_val_4 = *gpio_addr;

	printf("\nVal 1: %#04x\n", r_val_1);
	printf("\nVal 2: %#04x\n", r_val_2);
	printf("\nVal 3: %#04x\n", r_val_3);
	printf("\nVal 4: %#04x\n", r_val_4);
*/
	// allocate storage
	storage = (int *) malloc(1000 * sizeof(int));
	// check if the storage is available
	if(storage != NULL) {
		printf("\n ok\n");
	}else {
		printf("\n fail\n");
	}
    // set pointers to start address
	cur_res = storage;
	out_res = storage;
	printf("\n run!\n");
	while (1){
		if (out_res != cur_res){
			printf("\n result: %p\n", *out_res);
			++out_res;
		}
	}
}


