cmake_minimum_required(VERSION 3.15...3.28)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

set(PROJECT_NAME "pdfx")
project(${PROJECT_NAME} LANGUAGES CXX)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64")
  set(ARCH "arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
  set(ARCH "arm")
else()
  set(ARCH "x64")
endif()
set(PDFIUM_VERSION "4690" CACHE STRING "Version of pdfium used")

set(PDFIUM_URL "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/${PDFIUM_VERSION}/pdfium-linux-${ARCH}.tgz")

# Download pdfium
include(${CMAKE_CURRENT_SOURCE_DIR}/../windows/DownloadProject.cmake)
download_project(
  PROJ
  pdfium
  URL
  ${PDFIUM_URL}
)

set(PLUGIN_NAME "pdfx_plugin")

# Read PDFium config from downloaded dir
include(${pdfium_SOURCE_DIR}/PDFiumConfig.cmake)

add_library(${PLUGIN_NAME} SHARED
  "pdfx.cc"
  "pdfx.h"
  "pdfx_plugin.cc"
)

# Apply settings
apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${pdfium_SOURCE_DIR}/include"
)

# Linux dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

target_link_libraries(${PLUGIN_NAME} PRIVATE 
  pdfium 
  flutter 
  PkgConfig::GTK
)

# Add bundle libraries for installation
set(pdfx_bundled_libraries
  "${PDFium_LIBRARY}"
  PARENT_SCOPE
)
