#!/bin/sh

#  ramdisk.sh
#  
#
#  Created by syscl/lighting/Yating Zhou on 16/4/9.
#

#================================= GLOBAL VARS ==================================

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the deploy.sh) to prevent errors.
#
export LC_NUMERIC="en_US.UTF-8"

#
# Prevent non-printable/control characters.
#
unset GREP_OPTIONS
unset GREP_COLORS
unset GREP_COLOR

#
# Display style setting.
#
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Located repository.
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Define vars.
#
gArgv=""
gDebug=1
gR_NAME=RAMDISK
gMnt=1
gVirtual_Disk=$(diskutil list | grep -i "disk image" | sed -e "s| (disk image):||" | awk -F'\/' '{print $3}')
gRAMDISK="/Volumes/$gR_NAME"
gAlloc_RAM=16777216

#
# Path and filename setup.
#
gInstallDameon="/usr/local/sbin"
gFrom="${REPO}/tools"
gConfig="/tmp/com.syscl.ramdisk.plist"
gRAMScript="${REPO}/ramdisk.sh"

#
#--------------------------------------------------------------------------------
#

function _PRINT_MSG()
{
    local message=$1

    if [[ $message =~ 'OK' ]];
      then
        local message=$(echo $message | sed -e 's/.*OK://')
        echo "[  ${GREEN}OK${OFF}  ] ${message}."
      else
        if [[ $message =~ 'FAILED' ]];
          then
            local message=$(echo $message | sed -e 's/.*FAILED://')
            echo "[${RED}FAILED${OFF}] ${message}."
          else
            if [[ $message =~ '--->' ]];
              then
                local message=$(echo $message | sed -e 's/.*--->://')
                echo "[ ${GREEN}--->${OFF} ] ${message}"
              else
                if [[ $message =~ 'NOTE' ]];
                  then
                    local message=$(echo $message | sed -e 's/.*NOTE://')
                    echo "[ ${RED}NOTE${OFF} ] ${message}."
                  else
                    if [[ $message =~ 'DEBUG' ]];
                      then
                        local message=$(echo $message | sed -e 's/.*DEBUG://')
                        echo "[${BLUE}DEBLOG${OFF}] ${message}."
                    fi
                fi
            fi
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function tidy_execute()
{
    if [ $gDebug -eq 0 ];
      then
        #
        # Using debug mode to output all the details.
        #
        _PRINT_MSG "DEBUG: $2"
        $1
      else
        #
        # Make the output clear.
        #
        $1 >/tmp/report 2>&1 && RETURN_VAL=0 || RETURN_VAL=1

        if [ "${RETURN_VAL}" == 0 ];
          then
            _PRINT_MSG "OK: $2"
          else
            _PRINT_MSG "FAILED: $2"
            cat /tmp/report
        fi

        rm /tmp/report &> /dev/null
    fi
}

#
#--------------------------------------------------------------------------------
#

function _initCache()
{
    #
    # Check if virtual disk has been mounted.
    #
    for disk in ${gVirtual_Disk[@]}
    do
      _checkRAM ${disk}
    done

    #
    # Mount RAMDSIK.
    #
    if [ $gMnt -eq 1 ];
      then
        diskutil erasevolume HFS+ ${gR_NAME} `hdiutil attach -nomount ram://${gAlloc_RAM}`
    fi

    #
    # Create target dir.
    #
    mkdir -p $gRAMDISK/Library/Developer/Xcode/DerivedData
    mkdir -p $gRAMDISK/Library/Developer/CoreSimulator/Devices
    mkdir -p $gRAMDISK/Library/Caches/Google
    mkdir -p $gRAMDISK/Library/Caches/com.apple.Safari/fsCachedData
    mkdir -p $gRAMDISK/Library/Caches/Firefox
}

#
#--------------------------------------------------------------------------------
#

function _checkRAM()
{
    #
    # Check if virtual disk is mounted.
    #
    local gDev=$1
    local gVirt=$(diskutil info $gDev | grep -i "Virtual" | tr '[:lower:]' '[:upper:]')

    if [[ `diskutil info $gDev` == *"YES"* ]];
      then
        #
        # Yes, virtual disk exist.
        #
        gMnt=1
        gR_NAME=$(diskutil list | grep -i "$gDev" | tail -n1 | awk  '{print $2}')
      else
        #
        # No, we need to mount virtual disk.
        #
        gMnt=0
    fi

}

#
#--------------------------------------------------------------------------------
#

function _printConfig()
{
    if [ -f ${gConfig} ];
      then
        rm ${gConfig}
    fi

    echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                                                           > "$gConfig"
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                          >> "$gConfig"
    echo '<plist version="1.0">'                                                                                                                           >> "$gConfig"
    echo '<dict>'                                                                                                                                          >> "$gConfig"
    echo '	<key>KeepAlive</key>'                                                                                                                          >> "$gConfig"
    echo '	<false/>'                                                                                                                                      >> "$gConfig"
    echo '	<key>Label</key>'                                                                                                                              >> "$gConfig"
    echo '	<string>com.syscl.ramdisk</string>'                                                                                                            >> "$gConfig"
    echo '	<key>ProgramArguments</key>'                                                                                                                   >> "$gConfig"
    echo '	<array>'                                                                                                                                       >> "$gConfig"
    echo '		<string>/etc/syscl.ramdisk</string>'                                                                                                       >> "$gConfig"
    echo '	</array>'                                                                                                                                      >> "$gConfig"
    echo '	<key>RunAtLoad</key>'                                                                                                                          >> "$gConfig"
    echo '	<true/>'                                                                                                                                       >> "$gConfig"
    echo '</dict>'                                                                                                                                         >> "$gConfig"
    echo '</plist>'                                                                                                                                        >> "$gConfig"
}

#
#--------------------------------------------------------------------------------
#

function _install_launch()
{
    tidy_execute "_printConfig" "Generate configuration file of syscl.ramdisk launch daemon"
    _PRINT_MSG "--->: Install syscl.ramdisk..."
    tidy_execute "sudo cp "${gConfig}" "/Library/LaunchDaemons"" "Install configuration of ramdisk daemon"
    tidy_execute "sudo cp "${gRAMScript}" "/etc/syscl.ramdisk"" "Install ramdisk script"
    tidy_execute "sudo chmod 744 /etc/syscl.ramdisk" "Fix permission"
    tidy_execute "sudo chown root:wheel /etc/syscl.ramdisk" "Fix own wheel"
    tidy_execute "sudo launchctl load /Library/LaunchDaemons/com.syscl.ramdisk.plist" "Trigger startup service of syscl.ramdisk"
    tidy_execute "rm $gConfig" "Clean up"
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    #
    # Get argument.
    #
    gArgv=$(echo "$@" | tr '[:lower:]' '[:upper:]')
    if [[ $# -eq 1 && "$gArgv" == "-D" || "$gArgv" == "-DEBUG" ]];
      then
        #
        # Yes, we do need a debug mode.
        #
        _PRINT_MSG "NOTE: Use ${BLUE}DEBUG${OFF} mode"
        gDebug=0
      else
        #
        # No, we need a clean output style.
        #
        gDebug=1
    fi

    #
    # Detect which progress to execute.
    #
    if [[ "${REPO}" == "/etc" ]];
      then
        #
        # Create virtual disk.
        #
        _initCache
      else
        #
        # No, install syscl.ramdisk.
        #
        _install_launch
    fi
}

#==================================== START =====================================

main "$@"

exit 0

#================================================================================