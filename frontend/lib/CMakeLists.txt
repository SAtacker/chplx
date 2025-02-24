# Copyright 2021-2023 Hewlett Packard Enterprise Development LP
# Other additional copyright holders may be indicated within.
#
# The entirety of this work is licensed under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
#
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# generate a git-version.cpp file during the cmake configure step.
# If one exists, the write-git-sha script will only update it if the
# values are different.
# If CHPL_DONT_BUILD_SHA is set in the ENV, the git-sha will always be xxxxxxxxxx
if(NOT EXISTS ${CHPL_CMAKE_PYTHON})
    find_package(Python COMPONENTS Interpreter)
    if(${Python_FOUND})
        set(CHPL_CMAKE_PYTHON ${Python_EXECUTABLE})
    else()
        message(FATAL_ERROR "failed to find Python")
    endif()
endif()
if (EXISTS ${CMAKE_SOURCE_DIR}/.git)
        execute_process(COMMAND ${CHPL_CMAKE_PYTHON}
                                ${CMAKE_SOURCE_DIR}/frontend/util/config/write-git-sha
                                ${CMAKE_CURRENT_SOURCE_DIR}/util
                                --build-version
                                --chpl-home=${CHPL_HOME})
        message(STATUS "wrote git-version.cpp")
elseif(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/util/git-version.cpp)
# if we are not in a git repo, but we don't already have a git-version.cpp file,
# write one as if CHPL_DONT_BUILD_SHA was set so we dont execute the git command

        execute_process(COMMAND ${CMAKE_COMMAND} -E env
                        CHPL_DONT_BUILD_SHA=1
                        ${CHPL_CMAKE_PYTHON}
                        ${CMAKE_SOURCE_DIR}/frontend/util/config/write-git-sha
                        ${CMAKE_CURRENT_SOURCE_DIR}/util
        --build-version
        --chpl-home=${CHPL_HOME})
        message(STATUS "wrote git-version.cpp")
endif()

add_library(git-sha-obj OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/util/git-version.cpp)
set_target_properties(git-sha-obj PROPERTIES FOLDER "Frontend/Support")

# turn on position-independent code so we can use the same
# git-sha-obj for both a static and dynamic library
set_property(TARGET git-sha-obj PROPERTY POSITION_INDEPENDENT_CODE 1)

add_library(ChplFrontend-obj OBJECT
    ${CMAKE_CURRENT_SOURCE_DIR}/immediates/ifa_vars.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/immediates/hash_multipliers.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/immediates/num.cpp
)
set_target_properties(ChplFrontend-obj PROPERTIES FOLDER "Frontend")

# turn on position-independent code so we can use the same
# dyno-obj for both a static and dynamic library
set_property(TARGET ChplFrontend-obj PROPERTY POSITION_INDEPENDENT_CODE 1)

# Include the public library .h files as well as any generated .h files
target_include_directories(ChplFrontend-obj PUBLIC
                           ${LLVM_INCLUDE_DIRS}
                           ${CLANG_INCLUDE_DIRS}
                           ${CHPL_MAIN_INCLUDE_DIR}
                           ${CHPL_INCLUDE_DIR})

# Library code can also use headers from the lib/ directory
# but these are not to be public
target_include_directories(ChplFrontend-obj PRIVATE 
                           ${LLVM_INCLUDE_DIRS}
                           ${CLANG_INCLUDE_DIRS}
                           ${CMAKE_CURRENT_SOURCE_DIR})

# SHELL: is needed here to remove unwanted quotes from the list of arguments
# COMPILE_LANGUAGE:CXX is needed here to make sure we only set the flags
# for C++ files, not C files.
target_compile_options(ChplFrontend-obj PUBLIC
                       SHELL:$<$<COMPILE_LANGUAGE:CXX>:${CHPL_LLVM_COMP_ARGS}>)

# Don't build the git-sha-obj into ChplFrontend if CHPL_DONT_BUILD_SHA is set
# in the environment. Note that the value doesn't matter, just the presence of
# the var
if(MSVC)
  set(ChplFrontend_MODE STATIC)
else()
  set(ChplFrontend_MODE SHARED)
endif()

add_library(ChplFrontend ${ChplFrontend_MODE}
            $<TARGET_OBJECTS:ChplFrontend-obj>
            $<TARGET_OBJECTS:git-sha-obj>)
set_target_properties(ChplFrontend PROPERTIES FOLDER "Frontend")

target_include_directories(ChplFrontend PUBLIC
                           ${LLVM_INCLUDE_DIRS}
                           ${CHPL_MAIN_INCLUDE_DIR}
                           ${CHPL_INCLUDE_DIR})

add_subdirectory(immediates)
add_subdirectory(parsing)
add_subdirectory(framework)
add_subdirectory(resolution)
add_subdirectory(types)
add_subdirectory(uast)
add_subdirectory(util)

if(APPLE)
  #if (CHPL_LLVM_VERSION VERSION_LESS 14.0)
    # we see problems with statically linking and using PUBLIC
    # here because we are building a shared object & that would
    # include some of the LLVM libraries. But this pattern seems
    # to work OK with LLVM 14.
    #message(FATAL_ERROR "LLVM >= 14.0 required for MacOS builds")
  #endif()
  # link the LLVM dependencies with the generated .dylib
  # (we get linker errors on Mac OS X here if it uses INTERFACE)
  # an alternative would be to add link option -undefined dynamic_lookup
  target_link_libraries(ChplFrontend PUBLIC ${CHPL_LLVM_LINK_ARGS} ${llvm_libs})
elseif(CYGWIN)
  # (we also get linker errors on Cygwin if it uses INTERFACE here)
  target_link_libraries(ChplFrontend PUBLIC ${CHPL_LLVM_LINK_ARGS})
elseif(MSVC)
  # (we also get linker errors on Cygwin if it uses INTERFACE here)
  target_link_libraries(ChplFrontend PUBLIC ${CHPL_LLVM_LINK_ARGS} ${llvm_libs})
else()
  # Using PUBLIC here causes problems in some configurations with LLVM<14
  # when the LLVM libraries are included in the .so generated here
  # and also linked in statically with the resulting executable.
  # With INTERFACE, the LLVM libraries are only linked with at
  # the time that this library is used.
  target_link_libraries(ChplFrontend INTERFACE ${CHPL_LLVM_LINK_ARGS})
endif()

# TODO: Get printchplenv output proper so that we don't need to SHELL here
target_compile_options(ChplFrontend PUBLIC
                       SHELL:$<$<COMPILE_LANGUAGE:CXX>:${CHPL_LLVM_COMP_ARGS}>)


# TODO: ADDITIONAL_CLEAN_FILES requires cmake v3.15 ...
#       Can we find another way to mark these files for cleanup?
set_target_properties(ChplFrontend PROPERTIES
                      ADDITIONAL_CLEAN_FILES
                      ${CMAKE_CURRENT_SOURCE_DIR}/util/git-version.cpp)


# install ChplFrontend
# TODO: also install headers with PUBLIC_HEADER DESTINATION <dir>
if (INSTALLATION_MODE STREQUAL "prefix")
  install(TARGETS ChplFrontend
          LIBRARY DESTINATION
          "lib/chapel/${CHPL_MAJOR_VERSION}.${CHPL_MINOR_VERSION}/compiler")
else()
  install(TARGETS ChplFrontend
          LIBRARY DESTINATION
          "lib/compiler/${CHPL_HOST_BIN_SUBDIR}")
endif()
