cmake_minimum_required(VERSION 3.14.0 FATAL_ERROR)
project(ExampleImageFilterGLSL)

set(CMAKE_FRAMEWORK_PATH ../../../framework)
find_library(VUO_FRAMEWORK Vuo)

set(userModules "~/Library/Application\ Support/Vuo/Modules")
file(MAKE_DIRECTORY ${userModules})

set(compiledNode ${PROJECT_BINARY_DIR}/example.imageFilter.brightness.vuonode)
add_custom_command(
	COMMAND ${VUO_FRAMEWORK}/../vuo-compile ${PROJECT_SOURCE_DIR}/example.imageFilter.brightness.c --output ${compiledNode}
	COMMAND cp ${compiledNode} ${userModules}
	OUTPUT ${compiledNode}
)
add_custom_target(node ALL DEPENDS ${compiledNode})
