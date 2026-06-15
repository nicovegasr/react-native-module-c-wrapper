import NativeCaesar from './NativeCaesarRn';

export const Caesar = {
  cipher: (text: string, shift: number): string =>
    NativeCaesar.cipher(text, shift),
  decipher: (text: string, shift: number): string =>
    NativeCaesar.decipher(text, shift),
};
