#!/bin/sh

#  fixUSB.sh
#
#
#  Created by syscl/lighting/Yating Zhou on 16/3/18.
#

#
# This script aims to unmount all external devices automatically before sleep.
#
# Without this procedure, various computers with OS X/Mac OS X(even on a real Mac) suffer from "Disk not ejected properly"
# issue when there're external devices plugged-in. That's the reason why I created this script to fix this issue. (syscl/lighting/Yating Zhou)
#
# All credit to Bernhard Baehr (bernhard.baehr@gmx.de), without his great sleepwatcher dameon, this fix will not be created.
#

#================================= GLOBAL VARS ==================================

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the deploy.sh) to prevent errors.
#
export LC_NUMERIC="en_US.UTF-8"

#
# Get user id.
#
let gID=$(id -u)

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

#
# Path and filename setup.
#
gInstall_Repo="/usr/local/sbin/"
gFrom="${REPO}/tools"
gConfig="/tmp/com.syscl.externalfix.sleepwatcher.plist"
gUSBSleepScript="/tmp/sysclusbfix.sleep"
gUSBWakeScript="/tmp/sysclusbfix.wake"
gRTWlan_kext=$(ls /Library/Extensions | grep -i "Rtw" | sed 's/.kext//')
gRTWlan_Repo="/Library/Extensions"
to_Plist="/Library/LaunchDaemons/com.syscl.externalfix.sleepwatcher.plist"
to_shell_sleep="/etc/sysclusbfix.sleep"
to_shell_wake="/etc/sysclusbfix.wake"
gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl

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

function _tidy_exec()
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

function _printConfig()
{

    _del ${gConfig}

    echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                                                           > "$gConfig"
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                          >> "$gConfig"
    echo '<plist version="1.0">'                                                                                                                           >> "$gConfig"
    echo '<dict>'                                                                                                                                          >> "$gConfig"
    echo '	<key>KeepAlive</key>'                                                                                                                          >> "$gConfig"
    echo '	<true/>'                                                                                                                                       >> "$gConfig"
    echo '	<key>Label</key>'                                                                                                                              >> "$gConfig"
    echo '	<string>com.syscl.externalfix.sleepwatcher</string>'                                                                                           >> "$gConfig"
    echo '	<key>ProgramArguments</key>'                                                                                                                   >> "$gConfig"
    echo '	<array>'                                                                                                                                       >> "$gConfig"
    echo '		<string>/usr/local/sbin/sleepwatcher</string>'                                                                                             >> "$gConfig"
    echo '		<string>-V</string>'                                                                                                                       >> "$gConfig"
    echo '		<string>-s /etc/sysclusbfix.sleep</string>'                                                                                                >> "$gConfig"
    echo '		<string>-w /etc/sysclusbfix.wake</string>'                                                                                                 >> "$gConfig"
    echo '	</array>'                                                                                                                                      >> "$gConfig"
    echo '	<key>RunAtLoad</key>'                                                                                                                          >> "$gConfig"
    echo '	<true/>'                                                                                                                                       >> "$gConfig"
    echo '</dict>'                                                                                                                                         >> "$gConfig"
    echo '</plist>'                                                                                                                                        >> "$gConfig"
}

#
#--------------------------------------------------------------------------------
#

function _createUSB_Sleep_Script()
{
    #
    # Remove previous script.
    #
    _del ${gUSBSleepScript}

    echo '#!/bin/sh'                                                                                                                                         > "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# This script aims to unmount all external devices automatically before sleep.'                                                                   >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Without this procedure, various computers with OS X/Mac OS X(even on a real Mac) suffer from "Disk not ejected properly"'                       >> "$gUSBSleepScript"
    echo '# issue when there're external devices plugged-in. That's the reason why I created this script to fix this issue. (syscl/lighting/Yating Zhou)'   >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# All credit to Bernhard Baehr (bernhard.baehr@gmx.de), without his great sleepwatcher dameon, this fix will not be created.'                     >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Added unmount Disk for "OS X" (c) syscl/lighting/Yating Zhou.'                                                                                  >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo 'diskutil list | grep -i "External" | sed -e "s| (external, physical):||" | xargs -I {} diskutil eject {}'                                         >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo '# Fix RTLWlanUSB sleep problem credit B1anker & syscl/lighting/Yating Zhou. @PCBeta.'                                                             >> "$gUSBSleepScript"
    echo '#'                                                                                                                                                >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"                                                                                                               >> "$gUSBSleepScript"
    echo 'gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")'                                                             >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo 'if [[ "$gMAC_adr" != 0 ]];'                                                                                                                       >> "$gUSBSleepScript"
    echo '  then'                                                                                                                                           >> "$gUSBSleepScript"
    echo '    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl'                                                                 >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo '    if [ ! -f $gRT_Config ];'                                                                                                                     >> "$gUSBSleepScript"
    echo '      then'                                                                                                                                       >> "$gUSBSleepScript"
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*rfoff.rtl)'                                                                 >> "$gUSBSleepScript"
    echo '    fi'                                                                                                                                           >> "$gUSBSleepScript"
    echo ''                                                                                                                                                 >> "$gUSBSleepScript"
    echo "    osascript -e 'quit app \"Wireless Network Utility\"'"                                                                                         >> "$gUSBSleepScript"
    echo '    echo "1" > "$gRT_Config"'                                                                                                                     >> "$gUSBSleepScript"
    echo '    open "/Applications/Wireless Network Utility.app"'                                                                                            >> "$gUSBSleepScript"
    echo 'fi'                                                                                                                                               >> "$gUSBSleepScript"
}

#
#--------------------------------------------------------------------------------
#

function _RTLWlanU()
{
    _del ${gUSBWakeScript}
    _del "/etc/syscl.usbfix.wake"

    gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")

    echo '#!/bin/sh'                                                                                                                                         > "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"                                                                                                               >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "if [ ! -f $gRT_Config ];"                                                                                                                         >> "$gUSBWakeScript"
    echo '  then'                                                                                                                                           >> "$gUSBWakeScript"
    echo "    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl"                                                                 >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "    if [ ! -f $gRT_Config ];"                                                                                                                     >> "$gUSBWakeScript"
    echo '      then'                                                                                                                                       >> "$gUSBWakeScript"
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*.rtl)'                                                                      >> "$gUSBWakeScript"
    echo '    fi'                                                                                                                                           >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "    osascript -e 'quit app \"Wireless Network Utility\"'"                                                                                         >> "$gUSBWakeScript"
    echo '    echo "0" > "$gRT_Config"'                                                                                                                     >> "$gUSBWakeScript"
    echo '    open "/Applications/Wireless Network Utility.app"'                                                                                            >> "$gUSBWakeScript"
    echo 'fi'                                                                                                                                               >> "$gUSBWakeScript"
}

#
#--------------------------------------------------------------------------------
#

function _fnd_RTW_Repo()
{
    if [ -z $gRTWlan_kext ];
      then
        #
        # RTWlan_kext is not in /Library/Extensions. Check /S*/L*/E*.
        #
        gRTWlan_kext=$(ls /System/Library/Extensions | grep -i "Rtw" | sed 's/.kext//')
        gRTWlan_Repo="/System/Library/Extensions"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _uinstall()
{
    _tidy_exec "sudo launchctl unload ${to_Plist}" "Unload ${to_Plist}"
    _del /Library/LaunchDaemons/de.bernhard-baehr.sleepwatcher.plist
    _del ${gInstall_Repo}
    _del ${to_Plist}
    _del ${to_shell_sleep}
    _del ${to_shell_wake}
}

#
#--------------------------------------------------------------------------------
#

function _del()
{
    local target_file=$1

    if [ -d ${target_file} ];
      then
        _tidy_exec "sudo rm -R ${target_file}" "Remove ${target_file}"
      else
        if [ -f ${target_file} ];
          then
            _tidy_exec "sudo rm ${target_file}" "Remove ${target_file}"
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _touch()
{
    local target_file=$1

    if [ ! -d ${target_file} ];
      then
        _tidy_exec "sudo mkdir ${target_file}" "Create ${target_file}"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _install()
{
    #
    # Generate configuration file of sleepwatcher launch demon.
    #
    _tidy_exec "_printConfig" "Generate configuration file of sleepwatcher launch daemon"

    #
    # Find RTW place.
    #
    _fnd_RTW_Repo

    #
    # Generate script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou.
    #
    _tidy_exec "_createUSB_Sleep_Script" "Generating script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou"

    #
    # Generate script to load RTWlanUSB upon sleep.
    #
    _tidy_exec "_RTLWlanU" "Generate script to load RTWlanUSB upon sleep"

    #
    # Install sleepwatcher daemon.
    #
    _PRINT_MSG "--->: Installing external devices sleep patch..."
    _touch "${gInstall_Repo}"
    _tidy_exec "sudo cp "${gFrom}/sleepwatcher" "${gInstall_Repo}"" "Install sleepwatcher daemon"
    _tidy_exec "sudo cp "${gConfig}" "${to_Plist}"" "Install configuration of sleepwatcher daemon"
    _tidy_exec "sudo cp "${gUSBSleepScript}" "${to_shell_sleep}"" "Install sleep script"
    _tidy_exec "sudo cp "${gUSBWakeScript}" "${to_shell_wake}"" "Install wake script"
    _tidy_exec "sudo chmod 744 ${to_shell_sleep}" "Fix the permissions of ${to_shell_sleep}"
    _tidy_exec "sudo chmod 744 ${to_shell_wake}" "Fix the permissions of ${to_shell_wake}"
    _tidy_exec "sudo launchctl load ${to_Plist}" "Trigger startup service of syscl.usb.fix"

    #
    # Clean up.
    #
    _tidy_exec "rm $gConfig $gUSBSleepScript" "Clean up"

    #
    # Finish. Request reboot.
    #
    _PRINT_MSG "NOTE: DONE! Sleep to see change"
    _PRINT_MSG "NOTE: Feel free to post issue on https://github.com/syscl/Fix-usb-sleep"
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
    if [[ "$gArgv" == *"-D"* || "$gArgv" == *"-DEBUG"* ]];
      then
        #
        # Yes, we do need debug mode.
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
    if [[ "$gArgv" == *"-U"* ]];
      then
        #
        # Uninstall.
        #
        _uinstall
      else
        #
        # Install.
        #
        _install
    fi
}

#==================================== START =====================================

main "$@"

#================================================================================

exit ${RETURN_VAL}