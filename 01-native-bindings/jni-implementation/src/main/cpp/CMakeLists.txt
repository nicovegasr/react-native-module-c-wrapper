cmake_minimum_required(VERSION 3.22)
project(caesar-jni LANGUAGES C)

# libcaesar.so prebuilt — declarado como IMPORTED para que CMake lo enlace
# sin recompilarlo. ANDROID_ABI lo inyecta AGP por configuración (arm64-v8a,
# x86_64). El .so vive en jniLibs/ y termina embebido en el AAR final.
add_library(caesar SHARED IMPORTED)
set_target_properties(caesar PROPERTIES
    IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libcaesar.so)

# Bridge JNI: nuestro caesar_jni.c → libcaesar-jni.so
add_library(caesar-jni SHARED caesar_jni.c)
target_include_directories(caesar-jni PRIVATE ${CMAKE_SOURCE_DIR}/../cpp-include)
target_link_libraries(caesar-jni PRIVATE caesar log)
