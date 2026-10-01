cmake_minimum_required(VERSION 3.20)

project(apollo_native LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Keep every generator's artifacts in predictable locations. This also avoids
# Visual Studio adding a configuration subdirectory below lib/ and bin/.
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
foreach(config Debug Release RelWithDebInfo MinSizeRel)
  string(TOUPPER "${config}" config_upper)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${config_upper} "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${config_upper} "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${config_upper} "${CMAKE_BINARY_DIR}/bin")
endforeach()

# Build the vendored GLFW as a shared library. The Odin binding consequently
# has one stable system-library name per OS and does not depend on binaries
# hidden inside the Odin compiler distribution.
set(GLFW_LIBRARY_TYPE SHARED CACHE STRING "" FORCE)
set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL ON CACHE BOOL "" FORCE)
if(UNIX AND NOT APPLE)
  set(GLFW_BUILD_X11 ON CACHE BOOL "" FORCE)
  set(GLFW_BUILD_WAYLAND OFF CACHE BOOL "" FORCE)
endif()
add_subdirectory(vendor/glfw)

set(apollo_ui_sources
  vendor/imgui/imgui.cpp
  vendor/imgui/imgui_demo.cpp
  vendor/imgui/imgui_draw.cpp
  vendor/imgui/imgui_tables.cpp
  vendor/imgui/imgui_widgets.cpp
  vendor/imgui/backends/imgui_impl_glfw.cpp
  vendor/imgui/backends/imgui_impl_opengl3.cpp
  vendor/generated/imgui/dcimgui.cpp
  vendor/implot/implot.cpp
  vendor/implot/implot_demo.cpp
  vendor/implot/implot_items.cpp
  vendor/cimplot/cimplot.cpp
)

add_library(apollo_ui STATIC ${apollo_ui_sources})
target_include_directories(apollo_ui PRIVATE
  vendor/imgui
  vendor/imgui/backends
  vendor/generated/imgui
  vendor/implot
  vendor/cimgui
  vendor/cimplot
  vendor/glfw/include
)
target_compile_definitions(apollo_ui PRIVATE
  CIMGUI_NO_EXPORT
  IMGUI_DISABLE_OBSOLETE_FUNCTIONS
  IMGUI_DISABLE_OBSOLETE_KEYIO
  "IMGUI_IMPL_API=extern \"C\""
)
target_link_libraries(apollo_ui PRIVATE glfw)

install(TARGETS apollo_ui glfw
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
