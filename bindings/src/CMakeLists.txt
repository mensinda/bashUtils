cmake_minimum_required(VERSION 2.8.8)

project( BASHbinding )

set( SRC binding.c vars.c )
set( CMAKE_C_STANDARD 11 )

add_library( BASHbinding STATIC ${SRC} )
