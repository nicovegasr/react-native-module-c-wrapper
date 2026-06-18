# CMakeLists del módulo Android. Lo incluye el build de la app vía autolinking
# (ver react-native.config.js). Define el target `react-native-caesar` que el
# `appmodules` enlaza, juntando el dominio C, el adaptador C++ y el TurboModule.
cmake_minimum_required(VERSION 3.22)
project(react-native-caesar)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CAESAR_ROOT       ${CMAKE_CURRENT_SOURCE_DIR}/../../..)
set(DOMAIN_DIR        ${CAESAR_ROOT}/domain)
set(CPP_ADAPTER_DIR   ${CAESAR_ROOT}/infrastructure/cpp-adapter)
set(TURBO_CPP_DIR     ${CAESAR_ROOT}/infrastructure/turbo-module/cpp)

add_library(react-native-caesar
  SHARED
  ${DOMAIN_DIR}/caesar.c
  ${CPP_ADAPTER_DIR}/CaesarCipher.cpp
  ${TURBO_CPP_DIR}/CaesarTurboModule.cpp
)

target_include_directories(react-native-caesar PUBLIC
  ${DOMAIN_DIR}
  ${CPP_ADAPTER_DIR}
  ${TURBO_CPP_DIR}
)

# Visibility default: the host app (libappmodules.so) links to
# CaesarTurboModule's constructor and JSI methods, which need to be exported.

# react_codegen_CaesarSpec lo genera codegen en generated/jni/.
# ReactAndroid::reactnative + fbjni los aporta el build de la app.
target_link_libraries(react-native-caesar
  react_codegen_CaesarSpec
  ReactAndroid::reactnative
  fbjni::fbjni
)
