import NativeCaesar from './NativeCaesar';

export function encrypt(text: string, shift: number): Promise<string> {
  return NativeCaesar.encrypt(text, shift);
}

export function decrypt(text: string, shift: number): Promise<string> {
  return NativeCaesar.decrypt(text, shift);
}

// Variantes sync: bloquean el hilo de JS. Solo para textos pequeños.
export function encryptSync(text: string, shift: number): string {
  return NativeCaesar.encryptSync(text, shift);
}

export function decryptSync(text: string, shift: number): string {
  return NativeCaesar.decryptSync(text, shift);
}
