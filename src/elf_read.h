#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

void load_elf(const char *);
uint32_t get_word_addr(uint32_t);
void free_mem(void);
#ifdef __cplusplus
}
#endif
