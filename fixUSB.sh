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
# Path and filename setup.
#
gInstallDameon="/usr/local/sbin"
gFrom="${REPO}/tools"
gConfig="/tmp/de.bernhard-baehr.sleepwatcher.plist"
gUSBSleepScript="/tmp/sysclusbfix.sleep"

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
    echo '	<true/>'                                                                                                                                       >> "$gConfig"
    echo '	<key>Label</key>'                                                                                                                              >> "$gConfig"
    echo '	<string>de.bernhard-baehr.sleepwatcher</string>'                                                                                               >> "$gConfig"
    echo '	<key>ProgramArguments</key>'                                                                                                                   >> "$gConfig"
    echo '	<array>'                                                                                                                                       >> "$gConfig"
    echo '		<string>/usr/local/sbin/sleepwatcher</string>'                                                                                             >> "$gConfig"
    echo '		<string>-V</string>'                                                                                                                       >> "$gConfig"
    echo '		<string>-s /etc/sysclusbfix.sleep</string>'                                                                                                >> "$gConfig"
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
    if [ -f ${gUSBSleepScript} ];
      then
        rm ${gUSBSleepScript}
    fi

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
    echo 'diskutil list | grep -i "External" | sed -e "s| (external, physical):||" | xargs -I {} diskutil eject {}'                                   >> "$gUSBSleepScript"
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    #
    # Generate configuration file of sleepwatcher launch demon.
    #
    _PRINT_MSG "--->: Generating configuration file of sleepwatcher launch daemon..."
    tidy_execute "_printConfig" "Generate configuration file of sleepwatcher launch daemon"

    #
    # Generate script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou.
    #
    _PRINT_MSG "--->: Generating script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou..."
    tidy_execute "_createUSB_Sleep_Script" "Generating script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou"

    #
    # Install sleepwatcher daemon.
    #
    _PRINT_MSG "--->: Install sleepwatcher daemon..."
    tidy_execute "sudo cp "${gFrom}/sleepwatcher" "${gInstallDameon}"" "Install sleepwatcher daemon"
    tidy_execute "sudo cp "${gConfig}" "/Library/LaunchDaemons"" "Install configuration of sleepwatcher daemon"
    tidy_execute "sudo cp "${gUSBSleepScript}" "/etc"" "Install sleepwatcher script"
    tidy_execute "sudo chmod +x /etc/sysclusbfix.sleep" "Change the permissions of the script (add +x) so that it can be run before sleep"

    #
    # Clean up.
    #
    tidy_execute "rm $gConfig $gUSBSleepScript" "Clean up"

    #
    # Finish. Request reboot.
    #
    _PRINT_MSG "NOTE: DONE! Please reboot to see change! If you have any questions or bugs to report, post issue on https://github.com/syscl/Fix-usb-sleep. THX :-)"
}

#==================================== START =====================================

main

#================================================================================

exit ${RETURN_VAL}
