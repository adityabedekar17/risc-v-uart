#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <elf.h>

#ifdef __cplusplus
extern "C" {
#endif
  static uint32_t *elf_program;

  void load_elf(const char *path){
    FILE *elf_file = fopen(path, "rb");
    if (elf_file == NULL){
      printf("Failed reading elf file\n");
      exit(EXIT_FAILURE);
    }

    Elf32_Ehdr elf_head;
    Elf32_Phdr elf_phead;

    fread(&elf_head, sizeof(elf_head), 1, elf_file);

    fseek(elf_file, elf_head.e_phoff, 0);
    fread(&elf_phead, sizeof(elf_phead), 1, elf_file);

    Elf32_Off elf_program_offset = elf_phead.p_offset;
    uint32_t elf_program_size = elf_phead.p_memsz;
    
    elf_program = (uint32_t *) calloc(sizeof(uint32_t), elf_program_size);
    fseek(elf_file, elf_program_offset, 0);
    fread(elf_program, sizeof(uint32_t), elf_program_size, elf_file);
    fclose(elf_file);
  }

  uint32_t get_word_addr(uint32_t word_addr){
    return *(elf_program + word_addr);
  }
  
  void free_mem(void){
    free(elf_program);
  }
#ifdef __cplusplus
}
#endif
