cmake_minimum_required(VERSION 2.8.8)

project( BASHbinding )

find_package ( Threads )

set( SRC binding.c tidVector.c utils.c )
set( CMAKE_C_STANDARD 11 )

add_library( BASHbinding STATIC ${SRC} )
target_link_libraries( BASHbinding ${CMAKE_THREAD_LIBS_INIT} )
