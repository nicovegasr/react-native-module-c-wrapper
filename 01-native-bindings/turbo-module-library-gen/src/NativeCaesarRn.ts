import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  cipher(text: string, shift: number): string;
  decipher(text: string, shift: number): string;
}

export default TurboModuleRegistry.getEnforcing<Spec>('CaesarRn');
