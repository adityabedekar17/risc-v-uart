/* Print functions were taken from
 * https://github.com/YosysHQ/picorv32/blob/main/firmware/print.c
 */

#include <stdint.h>

#define OUTPORT 0x10000000

void putc(char ch){
  *((volatile uint32_t*)OUTPORT) = ch;
}

void print(const char *p){
  while (*p != 0){
    *((volatile uint32_t*)OUTPORT) = *(p++);
  }
}

void count(void){
  for (int i = 0; i < 256; i ++){
  }
  print("Hello from the ice40!\n");
  return;
}
