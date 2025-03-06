#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <stdbool.h>
#include <string.h>

#include <libserialport.h>

#include "elf_read.h"

#define WORD_BYTES 4
#define STACK_SIZE 32 * 1024
#define STACK_OFF 96 * 1024
#define MEM_SIZE 128 * 1024

uint32_t bytes_to_word_le(uint8_t buf[4]){
  uint32_t word = 0;
  for (size_t i = 0; i < WORD_BYTES; i ++){
    word |= (buf[i] << (i * 8));
  }
  return word;
}

void word_to_bytes_le(uint32_t word, uint8_t buf[4]){
  uint32_t mask = 0;
  for (size_t i = 0; i < WORD_BYTES; i ++){
    mask = (0xff << (i * 8));
    buf[i] = ((word & mask) >> (i * 8));
  }
}

int main(int argc, char * argv[]){
  if (argc < 3){
    printf("Usage: %s <port> <file>\n", argv[0]);
    exit(EXIT_FAILURE);
  }
  
  load_elf(argv[2]);

  struct sp_port *port;
  //enum sp_return ret;
  int ret;

  ret = 0;
  ret |= sp_get_port_by_name(argv[1], &port);
  ret |= sp_open(port, SP_MODE_READ_WRITE);
  ret |= sp_set_baudrate(port, 115200);
  ret |= sp_set_bits(port, 8);
  ret |= sp_set_parity(port, SP_PARITY_NONE);
  ret |= sp_set_stopbits(port, 1);
  if (ret != SP_OK){
    printf("Failed configuring port %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  // maximum nunber of bytes received is 9: 
  // {command, addr, data}
  uint8_t recv_buf[9];
  uint32_t addr, data;
  uint8_t send_buf[4];
  uint8_t byte_ok = 0xc8;
  bool first = true;
  struct timespec start, end;
  //char wstrb[5];
  //char wstrb_init[] = {'0', '0', '0', '0', '\0'};

  // the elf is given 128k of memory
  // 96k of which is program memory
  // 32k of which is the stack space
  uint32_t memory[STACK_SIZE >> 2];

  printf("Ready... press the reset button on the FPGA\n");

  while(1){
    sp_blocking_read(port, recv_buf, 1, 0);
    if (first){
      clock_gettime(CLOCK_REALTIME, &start);
      first = false;
    }
    if ((recv_buf[0] & 0xf0) == 0x20){
      sp_blocking_read(port, recv_buf + 1, 8, 0);
      addr = bytes_to_word_le(&recv_buf[1]);
      data = bytes_to_word_le(&recv_buf[5]);

      size_t addr_off = addr >> 2;
      addr_off -= STACK_OFF;

      if (addr > MEM_SIZE) {
        if (addr == 0x10000000) {
          putchar(data & 0xff);
        }
      }
      else {
        memory[addr_off] = 0;
        if (recv_buf[0] & 0x01){
          memory[addr_off] |= (data & 0x000000ff);
          //wstrb[0] = '1';
        }
        if (recv_buf[0] & 0x02){
          memory[addr_off] |= (data & 0x0000ff00);
          //wstrb[1] = '1';
        }
        if (recv_buf[0] & 0x04){
          memory[addr_off] |= (data & 0x00ff0000);
          //wstrb[2] = '1';
        }
        if (recv_buf[0] & 0x08){
          memory[addr_off] |= (data & 0xff000000);
          //wstrb[3] = '1';
        }
      }

      //printf("[wr %08x] %08x (wstrb=%s)\n", addr, data, wstrb);
      //memcpy(wstrb, wstrb_init, 5);
      sp_blocking_write(port, &byte_ok, 1, 0);
    }
    else if (recv_buf[0] == 0x77) {
      sp_blocking_read(port, recv_buf + 1, 4, 0);
      addr = bytes_to_word_le(&recv_buf[1]);
      if (addr > 0x00018000) {
        // within stack mem
        size_t addr_off = addr >> 2;
        addr_off -= STACK_OFF;

        data = memory[addr_off];
      }
      else {
        // within instr mem
        data = get_word_addr(addr >> 2);
        if (data == 0x00100073){
          printf("Received ebreak instr\n");
          break;
        }
      }
      word_to_bytes_le(data, send_buf);
      //printf("[rd %08x] %08x\n", addr, data);
      sp_blocking_write(port, send_buf, 4, 0);
    }
  }

  clock_gettime(CLOCK_REALTIME, &end);
  double elapsed = end.tv_sec - start.tv_sec;
  elapsed += (end.tv_nsec - start.tv_nsec) / 1000000000.0;
  printf("Completed in %f seconds.\n", elapsed);

  sp_close(port);
  sp_free_port(port);
  return 0;
}
