#ifndef NICOVEGASR_CAESAR_DOMAIN_H
#define NICOVEGASR_CAESAR_DOMAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Dominio: stand-in didáctico de una librería C de terceros.
 *
 * Símbolos prefijados con `caesar_` para evitar la colisión con encrypt(3)/
 * decrypt(3) de POSIX (<unistd.h>).
 *
 * Contrato:
 *  - output_buffer lo reserva el llamador, con capacidad >= strlen(text) + 1.
 *  - text termina en NUL.
 *  - Sin códigos de error (entrada válida => salida válida).
 *  - Sin estado: cada llamada es independiente y reentrante.
 */
void caesar_encrypt(const char* text, int key_shift, char* output_buffer);
void caesar_decrypt(const char* text, int key_shift, char* output_buffer);

#ifdef __cplusplus
}
#endif

#endif /* NICOVEGASR_CAESAR_DOMAIN_H */
