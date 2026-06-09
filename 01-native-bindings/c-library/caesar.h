#ifndef CAESAR_H
#define CAESAR_H

void encrypt(const char* text_to_cipher, int key_shift, char* output_buffer);
void decrypt(const char* text_to_decipher, int key_shift, char* output_buffer);

#endif /* CAESAR_H */
