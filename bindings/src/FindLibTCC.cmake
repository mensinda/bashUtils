# - Try to find TCC
# LIBTCC_ROOT can be set to specify the tcc root directory
# Once done this will define
#  LIBTCC_FOUND - System has TCC
#  LIBTCC_INCLUDE_DIRS - The TCC include directories
#  LIBTCC_LIBRARIES - The libraries needed to use TCC

find_path(    LIBTCC_INC NAMES libtcc.h PATHS ${LIBTCC_ROOT} )
find_library( LIBTCC_LIB NAMES tcc tcc1 PATHS ${LIBTCC_ROOT} )

set( LIBTCC_INCLUDE_DIRS ${LIBTCC_INC} )
set( LIBTCC_LIBRARIES    ${LIBTCC_LIB} )

include( FindPackageHandleStandardArgs )
find_package_handle_standard_args( LibTCC DEFAULT_MSG LIBTCC_INC LIBTCC_LIB )

mark_as_advanced( LIBTCC_INC LIBTCC_LIB )
