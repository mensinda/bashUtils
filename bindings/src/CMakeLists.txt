cmake_minimum_required(VERSION 2.8.8)

project( BASHbinding )

find_package ( Threads )

set( SRC ${PROJECT_SOURCE_DIR}/binding.c ${PROJECT_SOURCE_DIR}/tidVector.c ${PROJECT_SOURCE_DIR}/utils.c )
set( CMAKE_C_STANDARD 11 )
set( CMAKE_C_FLAGS -Wall )

set( CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR} )
set( LIBTCC_ROOT ${PROJECT_SOURCE_DIR}/tinycc )

find_package( LibTCC REQUIRED )

include_directories( ${LIBTCC_INCLUDE_DIRS} )
add_library( BASHbinding STATIC ${SRC} )
target_link_libraries( BASHbinding ${CMAKE_THREAD_LIBS_INIT} ${LIBTCC_LIBRARIES} ${CMAKE_DL_LIBS} )
