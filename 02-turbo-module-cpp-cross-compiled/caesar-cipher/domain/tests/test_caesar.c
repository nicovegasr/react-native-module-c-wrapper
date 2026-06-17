#include "caesar.h"

#include <assert.h>
#include <string.h>

static void encrypts_simple_lowercase(void) {
  char output[64];
  caesar_encrypt("abc", 1, output);
  assert(strcmp(output, "bcd") == 0);
}

static void wraps_around_the_alphabet(void) {
  char output[64];
  caesar_encrypt("xyz", 3, output);
  assert(strcmp(output, "abc") == 0);
}

static void preserves_case_for_uppercase(void) {
  char output[64];
  caesar_encrypt("ABC", 2, output);
  assert(strcmp(output, "CDE") == 0);
}

static void leaves_non_letters_untouched(void) {
  char output[64];
  caesar_encrypt("Hola, mundo!", 5, output);
  assert(strcmp(output, "Mtqf, rzsit!") == 0);
}

static void accepts_negative_shift(void) {
  char output[64];
  caesar_encrypt("bcd", -1, output);
  assert(strcmp(output, "abc") == 0);
}

static void accepts_shift_greater_than_alphabet(void) {
  char output[64];
  caesar_encrypt("abc", 27, output);
  assert(strcmp(output, "bcd") == 0);
}

static void handles_empty_string(void) {
  char output[64];
  caesar_encrypt("", 5, output);
  assert(strcmp(output, "") == 0);
}

static void decrypt_undoes_encrypt(void) {
  char encrypted[64];
  char decrypted[64];
  caesar_encrypt("Hello, World!", 7, encrypted);
  caesar_decrypt(encrypted, 7, decrypted);
  assert(strcmp(decrypted, "Hello, World!") == 0);
}

static void shift_zero_is_identity(void) {
  char output[64];
  caesar_encrypt("Anything goes.", 0, output);
  assert(strcmp(output, "Anything goes.") == 0);
}

int main(void) {
  encrypts_simple_lowercase();
  wraps_around_the_alphabet();
  preserves_case_for_uppercase();
  leaves_non_letters_untouched();
  accepts_negative_shift();
  accepts_shift_greater_than_alphabet();
  handles_empty_string();
  decrypt_undoes_encrypt();
  shift_zero_is_identity();
  return 0;
}
