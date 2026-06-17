#include "caesar.h"

#include <stddef.h>

static const int ALPHABET_SIZE = 26;

static int is_lowercase_letter(char character) {
  return character >= 'a' && character <= 'z';
}

static int is_uppercase_letter(char character) {
  return character >= 'A' && character <= 'Z';
}

static int wrap_around_alphabet(int shift) {
  return ((shift % ALPHABET_SIZE) + ALPHABET_SIZE) % ALPHABET_SIZE;
}

static char shift_letter(char letter, char first_letter_in_alphabet, int shift) {
  int position_in_alphabet = letter - first_letter_in_alphabet;
  int shifted_position = (position_in_alphabet + shift) % ALPHABET_SIZE;
  return (char)(first_letter_in_alphabet + shifted_position);
}

static char shift_character(char character, int shift) {
  if (is_lowercase_letter(character)) {
    return shift_letter(character, 'a', shift);
  }
  if (is_uppercase_letter(character)) {
    return shift_letter(character, 'A', shift);
  }
  return character;
}

void caesar_encrypt(const char* text, int key_shift, char* output_buffer) {
  int shift = wrap_around_alphabet(key_shift);
  size_t position = 0;
  while (text[position] != '\0') {
    output_buffer[position] = shift_character(text[position], shift);
    ++position;
  }
  output_buffer[position] = '\0';
}

void caesar_decrypt(const char* text, int key_shift, char* output_buffer) {
  caesar_encrypt(text, -key_shift, output_buffer);
}
