# react-native-test — app de ejemplo (enfoque ①)

App RN mínima para el **smoke test end-to-end** del módulo [`@nicovegasr/caesar-rn`](../turbo-module-library-gen/README.md): mete texto + shift y muestra `cipher`/`decipher` corriendo sobre los wrappers nativos.

```bash
yarn
cd ios && pod install && cd ..   # iOS: instala el pod 'Caesar' (path local)
yarn ios       # simulador iOS
yarn android   # emulador Android (con un AVD corriendo)
```

Consume el módulo por path local (`file:../turbo-module-library-gen`). Para el cableado y los problemas comunes, ver el [README del módulo](../turbo-module-library-gen/README.md) y el [README del enfoque ①](../README.md).
