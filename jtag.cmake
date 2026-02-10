function(add_jtag_debug_config)
    cmake_parse_arguments(ARG "" "NAME;ELF;OPENOCD;BOARD_CFG;PORT" "" ${ARGN})

    if(NOT ARG_NAME)
        set(ARG_NAME "Debug JTAG")
    endif()
    if(NOT ARG_OPENOCD)
        set(ARG_OPENOCD "openocd")
    endif()
    if(NOT ARG_BOARD_CFG)
        set(ARG_BOARD_CFG "board/esp32s3-builtin.cfg")
    endif()
    if(NOT ARG_PORT)
        set(ARG_PORT "3333")
    endif()

    # Sanitize name for filename
    string(REPLACE " " "_" CONFIG_FILENAME "${ARG_NAME}")

    set(RUN_CONFIG_DIR "${CMAKE_SOURCE_DIR}/.idea/runConfigurations")
    file(MAKE_DIRECTORY "${RUN_CONFIG_DIR}")

    file(WRITE "${RUN_CONFIG_DIR}/${CONFIG_FILENAME}.xml"
"<component name=\"ProjectRunConfigurationManager\">
  <configuration default=\"false\" name=\"${ARG_NAME}\" type=\"com.jetbrains.cidr.embedded.customGDBServer.CPPEnvironmentCustomGDBServerRunConfigurationType\" factoryName=\"com.jetbrains.cidr.embedded.customGDBServer.CPPEnvironmentCustomGDBServerRunConfigurationFactory\">
    <GDB_SERVER_SETTINGS>
      <option name=\"executablePath\" value=\"${ARG_ELF}\" />
      <option name=\"gdbServerPath\" value=\"${ARG_OPENOCD}\" />
      <option name=\"gdbServerArgs\" value=\"-f ${ARG_BOARD_CFG}\" />
      <option name=\"gdbServerPort\" value=\"${ARG_PORT}\" />
      <option name=\"autoStartServer\" value=\"true\" />
    </GDB_SERVER_SETTINGS>
    <GDB_STARTUP_COMMANDS>set remote hardware-watchpoint-limit 2
set remote hardware-breakpoint-limit 2
mon reset halt
flushregs</GDB_STARTUP_COMMANDS>
    <method v=\"2\" />
  </configuration>
</component>
")

    message(STATUS "Generated CLion JTAG debug config: ${ARG_NAME}")
endfunction()
