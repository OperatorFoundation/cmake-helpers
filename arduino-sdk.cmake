#
# ArduinoSDK.cmake
# Helper functions for linking Arduino SDK headers to CMake targets
# Supports: ESP32, RP2040, Teensy
#

# Find Arduino installation path across different platforms
function(_find_arduino_path out_var)
    if(DEFINED ENV{ARDUINO_DIRECTORIES_USER})
        set(${out_var} $ENV{ARDUINO_DIRECTORIES_USER} PARENT_SCOPE)
    elseif(EXISTS "$ENV{HOME}/.arduino15")
        set(${out_var} "$ENV{HOME}/.arduino15" PARENT_SCOPE)
    elseif(EXISTS "$ENV{HOME}/Library/Arduino15")
        set(${out_var} "$ENV{HOME}/Library/Arduino15" PARENT_SCOPE)
    elseif(DEFINED ENV{LOCALAPPDATA} AND EXISTS "$ENV{LOCALAPPDATA}/Arduino15")
        set(${out_var} "$ENV{LOCALAPPDATA}/Arduino15" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Could not find Arduino installation path. Please set ARDUINO_DIRECTORIES_USER environment variable.")
    endif()
endfunction()

# Find the latest version of a package
function(_find_latest_version package_path out_var)
    file(GLOB versions "${package_path}/*")
    if(NOT versions)
        message(FATAL_ERROR "No versions found in ${package_path}")
    endif()
    
    list(SORT versions)
    list(REVERSE versions)
    list(GET versions 0 latest)
    set(${out_var} ${latest} PARENT_SCOPE)
endfunction()

# Configure ESP32 SDK
function(_configure_esp32_sdk target_name sdk_path)
    message(STATUS "Configuring ESP32 SDK for ${target_name}")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Core includes
    target_include_directories(${target_name} PRIVATE
        ${sdk_path}/cores/esp32
    )
    
    # Common libraries
    set(esp32_libraries
        Wire
        SPI
        SD
        FS
        SPIFFS
        WiFi
        HTTPClient
        WebServer
        ESPmDNS
        Update
        Preferences
    )
    
    foreach(lib ${esp32_libraries})
        if(EXISTS "${sdk_path}/libraries/${lib}/src")
            target_include_directories(${target_name} PRIVATE
                ${sdk_path}/libraries/${lib}/src
            )
            message(STATUS "  Added library: ${lib}")
        endif()
    endforeach()
    
    # Toolchain-specific includes for ESP32-S3
    if(EXISTS "${sdk_path}/tools/sdk/esp32s3/include")
        file(GLOB esp32s3_includes "${sdk_path}/tools/sdk/esp32s3/include/*")
        foreach(inc ${esp32s3_includes})
            if(IS_DIRECTORY ${inc})
                target_include_directories(${target_name} PRIVATE ${inc})
            endif()
        endforeach()
    endif()
    
    # Toolchain-specific includes for ESP32
    if(EXISTS "${sdk_path}/tools/sdk/esp32/include")
        file(GLOB esp32_includes "${sdk_path}/tools/sdk/esp32/include/*")
        foreach(inc ${esp32_includes})
            if(IS_DIRECTORY ${inc})
                target_include_directories(${target_name} PRIVATE ${inc})
            endif()
        endforeach()
    endif()
endfunction()

# Configure RP2040 SDK
function(_configure_rp2040_sdk target_name sdk_path)
    message(STATUS "Configuring RP2040 SDK for ${target_name}")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Core includes
    target_include_directories(${target_name} PRIVATE
        ${sdk_path}/cores/rp2040
    )
    
    # Common libraries
    set(rp2040_libraries
        Wire
        SPI
        SD
        SDFS
        LittleFS
        WiFi
        HTTPClient
        WebServer
        lwIP_Ethernet
        lwIP_w5500
        lwIP_w5100
    )
    
    foreach(lib ${rp2040_libraries})
        if(EXISTS "${sdk_path}/libraries/${lib}/src")
            target_include_directories(${target_name} PRIVATE
                ${sdk_path}/libraries/${lib}/src
            )
            message(STATUS "  Added library: ${lib}")
        elseif(EXISTS "${sdk_path}/libraries/${lib}")
            target_include_directories(${target_name} PRIVATE
                ${sdk_path}/libraries/${lib}
            )
            message(STATUS "  Added library: ${lib}")
        endif()
    endforeach()
    
    # Pico SDK includes if available
    if(EXISTS "${sdk_path}/pico-sdk/src/common/pico_base/include")
        target_include_directories(${target_name} PRIVATE
            ${sdk_path}/pico-sdk/src/common/pico_base/include
        )
    endif()
endfunction()

# Configure Teensy SDK
function(_configure_teensy_sdk target_name sdk_path)
    message(STATUS "Configuring Teensy SDK for ${target_name}")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Core includes
    target_include_directories(${target_name} PRIVATE
        ${sdk_path}/cores/teensy4
        ${sdk_path}/cores/teensy3
    )
    
    # Common libraries
    set(teensy_libraries
        Wire
        SPI
        SD
        SerialFlash
        Audio
        Ethernet
        NativeEthernet
        USBHost_t36
        TimeLib
    )
    
    foreach(lib ${teensy_libraries})
        if(EXISTS "${sdk_path}/libraries/${lib}/src")
            target_include_directories(${target_name} PRIVATE
                ${sdk_path}/libraries/${lib}/src
            )
            message(STATUS "  Added library: ${lib}")
        elseif(EXISTS "${sdk_path}/libraries/${lib}")
            target_include_directories(${target_name} PRIVATE
                ${sdk_path}/libraries/${lib}
            )
            message(STATUS "  Added library: ${lib}")
        endif()
    endforeach()
endfunction()

# Main function: Link Arduino SDK to a target
# Usage: target_link_arduino_sdk(target_name PROCESSOR)
# Supported processors: ESP32, ESP32S3, RP2040, TEENSY, TEENSY40, TEENSY41
function(target_link_arduino_sdk target_name processor)
    # Find Arduino installation
    _find_arduino_path(arduino_path)
    message(STATUS "Arduino installation: ${arduino_path}")
    
    # Normalize processor name
    string(TOUPPER ${processor} processor_upper)
    
    # Determine package path based on processor
    if(processor_upper MATCHES "^ESP32")
        set(package_path "${arduino_path}/packages/esp32/hardware/esp32")
        _find_latest_version(${package_path} sdk_path)
        _configure_esp32_sdk(${target_name} ${sdk_path})
        set(processor_family "ESP32")
        
    elseif(processor_upper STREQUAL "RP2040")
        set(package_path "${arduino_path}/packages/rp2040/hardware/rp2040")
        _find_latest_version(${package_path} sdk_path)
        _configure_rp2040_sdk(${target_name} ${sdk_path})
        set(processor_family "RP2040")
        
    elseif(processor_upper MATCHES "^TEENSY")
        set(package_path "${arduino_path}/packages/teensy/hardware/avr")
        _find_latest_version(${package_path} sdk_path)
        _configure_teensy_sdk(${target_name} ${sdk_path})
        set(processor_family "TEENSY")
        
    else()
        message(FATAL_ERROR "Unsupported processor: ${processor}. Supported: ESP32, ESP32S3, RP2040, TEENSY")
    endif()
    
    # Store SDK information as target properties
    set_target_properties(${target_name} PROPERTIES
        ARDUINO_SDK_PATH ${sdk_path}
        ARDUINO_PROCESSOR ${processor}
        ARDUINO_PROCESSOR_FAMILY ${processor_family}
    )
    
    message(STATUS "Successfully configured Arduino SDK for ${target_name} (${processor})")
endfunction()

# Optional: Add a specific Arduino library to a target
# Usage: target_link_arduino_library(target_name library_name)
function(target_link_arduino_library target_name library_name)
    get_target_property(sdk_path ${target_name} ARDUINO_SDK_PATH)
    
    if(NOT sdk_path)
        message(FATAL_ERROR "Target ${target_name} does not have Arduino SDK configured. Call target_link_arduino_sdk first.")
    endif()
    
    # Try /src subdirectory first, then library root
    if(EXISTS "${sdk_path}/libraries/${library_name}/src")
        target_include_directories(${target_name} PRIVATE
            ${sdk_path}/libraries/${library_name}/src
        )
        message(STATUS "Added Arduino library to ${target_name}: ${library_name}")
    elseif(EXISTS "${sdk_path}/libraries/${library_name}")
        target_include_directories(${target_name} PRIVATE
            ${sdk_path}/libraries/${library_name}
        )
        message(STATUS "Added Arduino library to ${target_name}: ${library_name}")
    else()
        message(WARNING "Arduino library not found: ${library_name}")
    endif()
endfunction()

# Optional: Get SDK path for a configured target
# Usage: get_arduino_sdk_path(target_name out_var)
function(get_arduino_sdk_path target_name out_var)
    get_target_property(sdk_path ${target_name} ARDUINO_SDK_PATH)
    set(${out_var} ${sdk_path} PARENT_SCOPE)
endfunction()
