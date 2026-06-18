import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

// Spec = superficie pública del módulo nativo. Codegen genera de aquí la
// clase base C++ `NativeCaesarCxxSpec`. Cambio incompatible ⇒ major.
export interface Spec extends TurboModule {
  encrypt(text: string, shift: number): Promise<string>;
  decrypt(text: string, shift: number): Promise<string>;
  encryptSync(text: string, shift: number): string;
  decryptSync(text: string, shift: number): string;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCaesar');
