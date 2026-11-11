#----------------------------------------------------------------
# Generated CMake target import file for configuration "None".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "MbedTLS::everest" for configuration "None"
set_property(TARGET MbedTLS::everest APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::everest PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NONE "C"
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libeverest.a"
  )

list(APPEND _cmake_import_check_targets MbedTLS::everest )
list(APPEND _cmake_import_check_files_for_MbedTLS::everest "${_IMPORT_PREFIX}/lib/mbedtls3/libeverest.a" )

# Import target "MbedTLS::p256m" for configuration "None"
set_property(TARGET MbedTLS::p256m APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::p256m PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NONE "C"
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libp256m.a"
  )

list(APPEND _cmake_import_check_targets MbedTLS::p256m )
list(APPEND _cmake_import_check_files_for_MbedTLS::p256m "${_IMPORT_PREFIX}/lib/mbedtls3/libp256m.a" )

# Import target "MbedTLS::mbedcrypto" for configuration "None"
set_property(TARGET MbedTLS::mbedcrypto APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedcrypto PROPERTIES
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedcrypto.so.3.6.7"
  IMPORTED_SONAME_NONE "libmbedcrypto.so.16"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedcrypto )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedcrypto "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedcrypto.so.3.6.7" )

# Import target "MbedTLS::mbedx509" for configuration "None"
set_property(TARGET MbedTLS::mbedx509 APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedx509 PROPERTIES
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedx509.so.3.6.7"
  IMPORTED_SONAME_NONE "libmbedx509.so.7"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedx509 )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedx509 "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedx509.so.3.6.7" )

# Import target "MbedTLS::mbedtls" for configuration "None"
set_property(TARGET MbedTLS::mbedtls APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedtls PROPERTIES
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedtls.so.3.6.7"
  IMPORTED_SONAME_NONE "libmbedtls.so.21"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedtls )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedtls "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedtls.so.3.6.7" )

# Import target "MbedTLS::mbedcrypto_static" for configuration "None"
set_property(TARGET MbedTLS::mbedcrypto_static APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedcrypto_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NONE "C"
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedcrypto.a"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedcrypto_static )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedcrypto_static "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedcrypto.a" )

# Import target "MbedTLS::mbedx509_static" for configuration "None"
set_property(TARGET MbedTLS::mbedx509_static APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedx509_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NONE "C"
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedx509.a"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedx509_static )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedx509_static "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedx509.a" )

# Import target "MbedTLS::mbedtls_static" for configuration "None"
set_property(TARGET MbedTLS::mbedtls_static APPEND PROPERTY IMPORTED_CONFIGURATIONS NONE)
set_target_properties(MbedTLS::mbedtls_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NONE "C"
  IMPORTED_LOCATION_NONE "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedtls.a"
  )

list(APPEND _cmake_import_check_targets MbedTLS::mbedtls_static )
list(APPEND _cmake_import_check_files_for_MbedTLS::mbedtls_static "${_IMPORT_PREFIX}/lib/mbedtls3/libmbedtls.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
