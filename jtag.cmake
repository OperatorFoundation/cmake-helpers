include(FetchContent)

set(OPENOCD_ESP32_VERSION "0.12.0-esp32-20251215")
set(OPENOCD_ESP32_TAG "v${OPENOCD_ESP32_VERSION}")

if(APPLE)
    if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(OPENOCD_ARCHIVE "openocd-esp32-macos-arm64-${OPENOCD_ESP32_VERSION}.tar.gz")
    else()
        set(OPENOCD_ARCHIVE "openocd-esp32-macos-${OPENOCD_ESP32_VERSION}.tar.gz")
    endif()
elseif(UNIX)
    if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "aarch64")
        set(OPENOCD_ARCHIVE "openocd-esp32-linux-arm64-${OPENOCD_ESP32_VERSION}.tar.gz")
    else()
        set(OPENOCD_ARCHIVE "openocd-esp32-linux-amd64-${OPENOCD_ESP32_VERSION}.tar.gz")
    endif()
endif()

FetchContent_Declare(openocd_esp32
    URL "https://github.com/espressif/openocd-esp32/releases/download/${OPENOCD_ESP32_TAG}/${OPENOCD_ARCHIVE}"
)
FetchContent_MakeAvailable(openocd_esp32)

# Find GDB from Arduino toolchain
file(GLOB GDB_SEARCH "$ENV{HOME}/Library/Arduino15/packages/esp32/tools/xtensa-esp-elf-gdb/*/bin/xtensa-esp32s3-elf-gdb")
if(GDB_SEARCH)
    list(SORT GDB_SEARCH ORDER DESCENDING)
    list(GET GDB_SEARCH 0 ESP32S3_GDB)
else()
    find_program(ESP32S3_GDB xtensa-esp32s3-elf-gdb)
endif()

function(add_openocd_debug_config)
    cmake_parse_arguments(ARG "" "NAME;TARGET;ELF;BOARD_CFG;GDB" "" ${ARGN})

    if(NOT ARG_NAME)
        set(ARG_NAME "OpenOCD Debug")
    endif()
    if(NOT ARG_TARGET)
        set(ARG_TARGET "build_eden-horizon")
    endif()
    if(NOT ARG_BOARD_CFG)
        set(ARG_BOARD_CFG "${openocd_esp32_SOURCE_DIR}/share/openocd/scripts/board/esp32s3-builtin.cfg")
    endif()
    if(NOT ARG_GDB)
        set(ARG_GDB "${ESP32S3_GDB}")
    endif()

    # Make paths relative to project dir for portability
    string(REPLACE "${CMAKE_SOURCE_DIR}" "\$PROJECT_DIR\$" REL_ELF "${ARG_ELF}")
    string(REPLACE "${CMAKE_SOURCE_DIR}" "\$PROJECT_DIR\$" REL_BOARD_CFG "${ARG_BOARD_CFG}")
    # GDB is outside project, make relative to project parent
    string(REPLACE "$ENV{HOME}" "\$PROJECT_DIR\$/.." REL_GDB "${ARG_GDB}")

    string(REPLACE " " "_" CONFIG_FILENAME "${ARG_NAME}")

    set(RUN_CONFIG_DIR "${CMAKE_SOURCE_DIR}/.idea/runConfigurations")
    file(MAKE_DIRECTORY "${RUN_CONFIG_DIR}")

    file(WRITE "${RUN_CONFIG_DIR}/${CONFIG_FILENAME}.xml"
"<component name=\"ProjectRunConfigurationManager\">
  <configuration default=\"false\" name=\"${ARG_NAME}\" type=\"com.jetbrains.cidr.embedded.openocd.conf.type\" factoryName=\"com.jetbrains.cidr.embedded.openocd.conf.factory\" REDIRECT_INPUT=\"false\" ELEVATE=\"false\" USE_EXTERNAL_CONSOLE=\"false\" EMULATE_TERMINAL=\"false\" PASS_PARENT_ENVS_2=\"true\" PROJECT_NAME=\"eden\" TARGET_NAME=\"${ARG_TARGET}\" CONFIG_NAME=\"Debug\" version=\"1\" RUN_PATH=\"${REL_ELF}\">
    <openocd version=\"1\" gdb-port=\"3333\" telnet-port=\"4444\" board-config=\"${REL_BOARD_CFG}\" reset-type=\"INIT\" download-type=\"UPDATED_ONLY\">
      <debugger kind=\"GDB\">${REL_GDB}</debugger>
    </openocd>
    <method v=\"2\">
      <option name=\"CLION.COMPOUND.BUILD\" enabled=\"true\" />
    </method>
  </configuration>
</component>
")

    message(STATUS "Generated CLion OpenOCD debug config: ${ARG_NAME}")
endfunction()
