/* Print functions were taken from
 * https://github.com/YosysHQ/picorv32/blob/main/firmware/print.c
 */

#include <stdint.h>
#include <stddef.h>

#define OUTPORT 0x10000000

void putc(char ch){
  *((volatile uint32_t*)OUTPORT) = ch;
}

void print(const char *p){
  while (*p != 0){
    *((volatile uint32_t*)OUTPORT) = *(p++);
  }
}

char digit_to_char(uint8_t digit){
  char out;
  switch (digit) {
    case 0x0: out = '0'; break;
    case 0x1: out = '1'; break;
    case 0x2: out = '2'; break;
    case 0x3: out = '3'; break;

    case 0x4: out = '4'; break;
    case 0x5: out = '5'; break;
    case 0x6: out = '6'; break;
    case 0x7: out = '7'; break;

    case 0x8: out = '8'; break;
    case 0x9: out = '9'; break;
    case 0xa: out = 'a'; break;
    case 0xb: out = 'b'; break;

    case 0xc: out = 'c'; break;
    case 0xd: out = 'd'; break;
    case 0xe: out = 'e'; break;
    case 0xf: out = 'f'; break;
    default: out = 0;
  }
  return out;
}

void print_hex(unsigned int num, int digits){
  putc('0');
  putc('x');
  for (int i = (4*digits)-4; i >= 0; i -= 4){
    unsigned int mask = 0xf << i;
    char digit = digit_to_char((num & mask) >> i);
    putc(digit);
  }
}

void print_array(unsigned int array[], size_t len){
  for (size_t i = 0; i < len; i ++){
    print_hex(array[i], 8);
    putc(' ');
  }
  putc('\n');
}

void insertion_sort(unsigned int array[], size_t len){
  for (size_t i = 1; i < len; ++i){
    unsigned int curr = array[i];
    unsigned int j = i - 1;

    while (j >= 0 && (array[j] > curr)){
      array[j + 1] = array[j];
      j -= 1;
    }
    array[j + 1] = curr;
  }
}

void count(void){
  for (int i = 0; i < 256; i ++){
  }
  print("Hello from the ice40!\n");
  return;
}

void sort(void){
  unsigned int array[] = {20, 15, 12, 5, 1, 60, 500, 5};
  size_t len = 8;

  print_array(array, len);

  insertion_sort(array, len);

  print_array(array, len);
}
