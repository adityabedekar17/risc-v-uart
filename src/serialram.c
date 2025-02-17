#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include <libserialport.h>

static uint32_t memory[] = {
  0x3fc00093,
  0x0000a023,
  0x0000a103,
  0x00110113,
  0x0020a023,
  0xff5ff06f
};

int main(int argc, char * argv[]){

  if (argc < 3){
    // 2nd arg is currently unused, to be used for elf reader
    printf("Usage: %s <port> <file>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  struct sp_port *port;
  enum sp_return ret;

  ret = SP_OK;
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

  size_t msg_bytes = 4;
  char msg_buf[msg_bytes];
  size_t bytes_read;
  uint32_t mem_addr = 0;
  uint32_t mask = 0;

  while(1){
    ret = sp_blocking_read(port, msg_buf, msg_bytes, 0);
    if (ret != msg_bytes){
      printf("Failed reading %lu bytes\n", msg_bytes);
      exit(EXIT_FAILURE);
    }

    mem_addr = 0;
    bytes_read = (size_t) ret;
    for (size_t i = 0; i < bytes_read; i ++){
      mem_addr |= ((uint8_t) msg_buf[i] << (8 * i));
    }
    printf("Received address: 0x%08x\n", mem_addr);

    printf("Sending bytes: ");
    for (size_t i = 0; i < msg_bytes; i ++){
      mask = 0xff << (i * 8);
      uint8_t cur_byte = (memory[mem_addr >> 2] & mask) >> (i * 8);
      msg_buf[i] = cur_byte;
      printf("0x%02x ", cur_byte);
    }
    printf("\n");

    ret = sp_blocking_write(port, msg_buf, msg_bytes, 0);
    if (ret != msg_bytes){
      printf("Failed to write %lu bytes\n", msg_bytes);
      exit(EXIT_FAILURE);
    }
  }

  sp_close(port);
  sp_free_port(port);
  return 0;
}
