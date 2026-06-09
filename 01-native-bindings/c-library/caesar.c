#include "caesar.h"
#include <stdbool.h>

#define ALPHABET_SIZE 26

static bool is_lowercase(char letter) { return letter >= 'a' && letter <= 'z'; }
static bool is_uppercase(char letter) { return letter >= 'A' && letter <= 'Z'; }

static int wrap_to_alphabet(int index) {
    return (index % ALPHABET_SIZE + ALPHABET_SIZE) % ALPHABET_SIZE;
}

static char shift_letter(char letter, char base, int key_shift) {
    int alphabet_normalized_index = letter - base;
    int alphabet_shifted_index    = wrap_to_alphabet(alphabet_normalized_index + key_shift);
    char shifted_letter           = (char)(alphabet_shifted_index + base);
    return shifted_letter;
}

void encrypt(const char* text_to_cipher, int key_shift, char* output_buffer) {
    int current_index;
    for (current_index = 0; text_to_cipher[current_index] != '\0'; current_index++) {
        char letter = text_to_cipher[current_index];

        if (is_lowercase(letter)) {
            output_buffer[current_index] = shift_letter(letter, 'a', key_shift);
            continue;
        }
        if (is_uppercase(letter)) {
            output_buffer[current_index] = shift_letter(letter, 'A', key_shift);
            continue;
        }
        output_buffer[current_index] = letter;
    }
    output_buffer[current_index] = '\0';
}

void decrypt(const char* text_to_decipher, int key_shift, char* output_buffer) {
    encrypt(text_to_decipher, -key_shift, output_buffer);
}
