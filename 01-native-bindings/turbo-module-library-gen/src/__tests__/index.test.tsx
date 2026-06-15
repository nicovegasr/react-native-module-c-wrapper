import { describe, expect, it, jest } from '@jest/globals';

jest.mock('../NativeCaesarRn', () => ({
  __esModule: true,
  default: {
    cipher: jest.fn((text: string, shift: number) => `cipher(${text},${shift})`),
    decipher: jest.fn(
      (text: string, shift: number) => `decipher(${text},${shift})`
    ),
  },
}));

import { Caesar } from '../index';

describe('Caesar facade', () => {
  it('delegates cipher to the native module', () => {
    expect(Caesar.cipher('abc', 3)).toBe('cipher(abc,3)');
  });

  it('delegates decipher to the native module', () => {
    expect(Caesar.decipher('def', 3)).toBe('decipher(def,3)');
  });
});
