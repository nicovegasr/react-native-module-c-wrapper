jest.mock('../NativeCaesar', () => ({
  __esModule: true,
  default: {
    encrypt: jest.fn(async (text: string, shift: number) => `enc(${text},${shift})`),
    decrypt: jest.fn(async (text: string, shift: number) => `dec(${text},${shift})`),
    encryptSync: jest.fn((text: string, shift: number) => `encSync(${text},${shift})`),
    decryptSync: jest.fn((text: string, shift: number) => `decSync(${text},${shift})`),
  },
}));

import NativeCaesar from '../NativeCaesar';
import { decrypt, decryptSync, encrypt, encryptSync } from '../index';

describe('fachada JS', () => {
  it('encrypt delega en el módulo nativo', async () => {
    await expect(encrypt('abc', 3)).resolves.toBe('enc(abc,3)');
    expect(NativeCaesar.encrypt).toHaveBeenCalledWith('abc', 3);
  });

  it('decrypt delega en el módulo nativo', async () => {
    await expect(decrypt('def', 3)).resolves.toBe('dec(def,3)');
    expect(NativeCaesar.decrypt).toHaveBeenCalledWith('def', 3);
  });

  it('encryptSync delega en el módulo nativo', () => {
    expect(encryptSync('abc', 3)).toBe('encSync(abc,3)');
    expect(NativeCaesar.encryptSync).toHaveBeenCalledWith('abc', 3);
  });

  it('decryptSync delega en el módulo nativo', () => {
    expect(decryptSync('def', 3)).toBe('decSync(def,3)');
    expect(NativeCaesar.decryptSync).toHaveBeenCalledWith('def', 3);
  });
});
