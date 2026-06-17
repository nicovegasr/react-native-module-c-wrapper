# Build de HOST para el adaptador C++ sobre la librería C de dominio.
# Sirve para tests rápidos con GoogleTest. El build móvil NO usa este archivo:
# Android entra por caesar-cipher/infrastructure/turbo-module/android/CMakeLists.txt
# (autolinking) e iOS por Caesar.podspec.
cmake_minimum_required(VERSION 3.22)
project(CaesarCipher C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(DOMAIN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../domain)

add_library(caesar_cipher STATIC
  CaesarCipher.cpp
  ${DOMAIN_DIR}/caesar.c
)
target_include_directories(caesar_cipher PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${DOMAIN_DIR}
)
set_target_properties(caesar_cipher PROPERTIES
  POSITION_INDEPENDENT_CODE ON
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
)

option(CAESAR_BUILD_TESTS "Build host unit tests" OFF)

if(CAESAR_BUILD_TESTS)
  include(FetchContent)
  # TODO(supply-chain): fijar a commit SHA + URL_HASH cuando se congele la
  # versión de GoogleTest en el primer release.
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.15.2
  )
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(googletest)

  enable_testing()
  add_executable(caesar_cipher_tests tests/CaesarCipherTest.cpp)
  target_link_libraries(caesar_cipher_tests PRIVATE caesar_cipher GTest::gtest_main)

  include(GoogleTest)
  gtest_discover_tests(caesar_cipher_tests)
endif()
