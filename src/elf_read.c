#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <elf.h>

extern "C" {
  static FILE *elf_file;
  // how many bytes from 0 is the entry point?
  static Elf32_Off elf_program_offset;

  void load_elf(const char *path){
    elf_file = fopen(path, "rb");
    if (elf_file == NULL){
      printf("Failed reading elf file\n");
      exit(EXIT_FAILURE);
    }
    Elf32_Ehdr elf_head;
    Elf32_Phdr elf_phead;

    fread(&elf_head, sizeof(elf_head), 1, elf_file);

    fseek(elf_file, elf_head.e_phoff, 0);
    fread(&elf_phead, sizeof(elf_phead), 1, elf_file);

    elf_program_offset = elf_phead.p_offset;
    return;
  }
  uint32_t get_word_addr(uint8_t byte_addr){
    uint32_t instr;
    uint32_t rd_off = elf_program_offset + (byte_addr * 4);
    fseek(elf_file, rd_off, 0);
    fread(&instr, sizeof(instr), 1, elf_file);
    return instr;
  }
}
