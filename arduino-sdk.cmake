#
# ArduinoSDK.cmake
# Helper functions for adding Arduino SDK include paths for IDE support only
# Does NOT compile anything - that's handled by arduino-cli
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

# Recursively add all subdirectories that contain header files
function(_add_recursive_includes target_name base_path)
    if(IS_DIRECTORY ${base_path})
        file(GLOB_RECURSE header_files "${base_path}/*.h" "${base_path}/*.hpp")
        if(header_files)
            # Get unique directories containing headers
            set(include_dirs "")
            foreach(header ${header_files})
                get_filename_component(dir ${header} DIRECTORY)
                list(APPEND include_dirs ${dir})
            endforeach()
            list(REMOVE_DUPLICATES include_dirs)
            
            # Add all directories to include path
            foreach(dir ${include_dirs})
                target_include_directories(${target_name} SYSTEM PRIVATE ${dir})
            endforeach()
        endif()
    endif()
endfunction()

# Configure ESP32 SDK includes
function(_configure_esp32_sdk target_name sdk_path)
    message(STATUS "Adding ESP32 SDK includes for ${target_name} (IDE support only)")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Add cores
    _add_recursive_includes(${target_name} "${sdk_path}/cores/esp32")
    
    # Add all libraries
    _add_recursive_includes(${target_name} "${sdk_path}/libraries")
    
    # Add ESP32 toolchain includes (for soc/soc_caps.h, etc.)
    _add_recursive_includes(${target_name} "${sdk_path}/tools/sdk/esp32s3/include")
    _add_recursive_includes(${target_name} "${sdk_path}/tools/sdk/esp32/include")
    _add_recursive_includes(${target_name} "${sdk_path}/tools/sdk/esp32c3/include")
    _add_recursive_includes(${target_name} "${sdk_path}/tools/sdk/esp32c6/include")
    _add_recursive_includes(${target_name} "${sdk_path}/tools/sdk/esp32h2/include")
    
    message(STATUS "  ESP32 includes added")
endfunction()

# Configure RP2040 SDK includes
function(_configure_rp2040_sdk target_name sdk_path)
    message(STATUS "Adding RP2040 SDK includes for ${target_name} (IDE support only)")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Add cores
    _add_recursive_includes(${target_name} "${sdk_path}/cores/rp2040")
    
    # Add all libraries
    _add_recursive_includes(${target_name} "${sdk_path}/libraries")
    
    # Add Pico SDK if available
    _add_recursive_includes(${target_name} "${sdk_path}/pico-sdk")
    
    message(STATUS "  RP2040 includes added")
endfunction()

# Configure Teensy SDK includes
function(_configure_teensy_sdk target_name sdk_path)
    message(STATUS "Adding Teensy SDK includes for ${target_name} (IDE support only)")
    message(STATUS "  SDK path: ${sdk_path}")
    
    # Add cores
    _add_recursive_includes(${target_name} "${sdk_path}/cores")
    
    # Add all libraries
    _add_recursive_includes(${target_name} "${sdk_path}/libraries")
    
    message(STATUS "  Teensy includes added")
endfunction()

# Main function: Add Arduino SDK include paths to a target (for IDE support only)
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
    
    message(STATUS "Successfully added Arduino SDK includes for ${target_name} (${processor})")
endfunction()

# Optional: Add a specific Arduino library to a target
# Usage: target_link_arduino_library(target_name library_name)
function(target_link_arduino_library target_name library_name)
    get_target_property(sdk_path ${target_name} ARDUINO_SDK_PATH)
    
    if(NOT sdk_path)
        message(FATAL_ERROR "Target ${target_name} does not have Arduino SDK configured. Call target_link_arduino_sdk first.")
    endif()
    
    # Add library includes recursively
    if(EXISTS "${sdk_path}/libraries/${library_name}")
        _add_recursive_includes(${target_name} "${sdk_path}/libraries/${library_name}")
        message(STATUS "Added Arduino library includes to ${target_name}: ${library_name}")
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
