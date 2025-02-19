#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include <libserialport.h>

#define WORD_BYTES 4

static uint32_t memory[256];
void init_mem(void){ 
  memory[0] = 0x3fc00093;
  memory[1] = 0x0000a023;
  memory[2] = 0x0000a103;
  memory[3] = 0x00110113;
  memory[4] = 0x0020a023;
  memory[5] = 0xff5ff06f;
};

enum sp_return send_byte(struct sp_port *port, uint8_t byte){
  enum sp_return ret;
  char buf[1];
  buf[0] = byte;
  ret = sp_blocking_write(port, buf, 1, 0);
  if (ret != 1){
    printf("Failed to write byte %02x\n", byte);
    exit(EXIT_FAILURE);
  }
  return ret;
}

enum sp_return send_word(struct sp_port *port, uint32_t word){
  uint32_t mask;
  char word_buf[WORD_BYTES];
  for (size_t i = 0; i < WORD_BYTES; i ++){
    mask = 0xff << (i * 8);
    uint8_t cur_byte = (word & mask) >> (i * 8);
    word_buf[i] = cur_byte;
  }

  enum sp_return ret;
  ret = sp_blocking_write(port, word_buf, WORD_BYTES, 0);
  if (ret != WORD_BYTES){
    printf("Failed to write word %08x\n", word);
    exit(EXIT_FAILURE);
  }
  return ret;
}

enum sp_return read_words(struct sp_port *port, size_t num_words, uint32_t word[num_words]){
  enum sp_return ret;
  char word_buf[WORD_BYTES * num_words];
  ret = sp_blocking_read(port, word_buf, WORD_BYTES * num_words, 0);
  if (ret != WORD_BYTES * num_words) {
    printf("Failed reading word\n");
    exit(EXIT_FAILURE);
  }
  for(size_t j = 0; j < num_words; j ++) {
    uint32_t mem_addr = 0;
    for (size_t i = 0; i < WORD_BYTES; i ++){
      mem_addr |= ((uint8_t) word_buf[4 * j + i] << (8 * i));
    }
    word[j] = mem_addr;
  }
  return ret;
}

int main(int argc, char * argv[]){

  if (argc < 3){
    // 2nd arg is currently unused, to be used for elf reader
    printf("Usage: %s <port> <file>\n", argv[0]);
    exit(EXIT_FAILURE);
  }
  init_mem();

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

  uint8_t command;
  uint32_t addr, data;
  char buf[4];
  uint32_t words[2];
  while(1){
    ret = sp_blocking_read(port, buf, 1, 0);
    command = buf[0];
    if (ret != 1) {
      printf("Failed reading command\n");
      exit(EXIT_FAILURE);
    }
    // write
    if ( (command & 0xf0) == 0x20){
      read_words(port, 2, words);
      // TODO wstrb
      memory[words[0] >> 2] = words[1];
      printf("[wr %08x] %08x (wstrb=)\n", words[0], words[1]);
      send_byte(port, 0xc8);
    }
    // read
    else if (command == 0x77) {
      read_words(port, 1, &addr);
      data = memory[addr >> 2];
      printf("[rd %08x] %08x\n", addr, data);
      send_word(port, data);
    }
  }

  sp_close(port);
  sp_free_port(port);
  return 0;
}
