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
# LC_NUMERIC here (for the duration of the fixUSB.sh) to prevent errors.
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
gGitHubContentURL="https://raw.githubusercontent.com/syscl/Fix-usb-sleep/master"

#
#--------------------------------------------------------------------------------
#

function _PRINT_MSG()
{
    local message=$1

    case "$message" in
      OK*    ) local message=$(echo $message | sed -e 's/.*OK://')
               echo "[  ${GREEN}OK${OFF}  ] ${message}."
               ;;

      FAILED*) local message=$(echo $message | sed -e 's/.*://')
               echo "[${RED}FAILED${OFF}] ${message}."
               ;;

      ---*   ) local message=$(echo $message | sed -e 's/.*--->://')
               echo "[ ${GREEN}--->${OFF} ] ${message}"
               ;;

      NOTE*  ) local message=$(echo $message | sed -e 's/.*NOTE://')
               echo "[ ${RED}Note${OFF} ] ${message}."
               ;;
    esac
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

function _checkForExecutableFile()
{
    if [ ! -f ${gFrom}/sleepwatcher ];
      then
        _touch "${gFrom}/tools"
        _tidy_exec "sudo curl -o ${gFrom}/sleepwatcher --silent "${gGitHubContentURL}/tools/sleepwatcher"" "Download sleepwatcher"
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


    echo '#!/bin/sh'
    echo '#'
    echo '# This script aims to unmount all external devices automatically before sleep.'
    echo '#'
    echo '# Without this procedure, various computers with OS X/Mac OS X(even on a real Mac) suffer from "Disk not ejected properly"'
    echo '# issue when there're external devices plugged-in. That's the reason why I created this script to fix this issue. (syscl/lighting/Yating Zhou)'
    echo '#'
    echo '# All credit to Bernhard Baehr (bernhard.baehr@gmx.de), without his great sleepwatcher dameon, this fix will not be created.'
    echo '#'
    echo ''
    echo '#'
    echo '# Added unmount Disk for "OS X" (c) syscl/lighting/Yating Zhou.'
    echo '#'
    echo 'gMountPartition="/tmp/com.syscl.externalfix"'
    echo 'gDisk=($(diskutil list |grep -i -i "dev" |grep -i -o "disk[0-9]"))'
    echo ''
    echo 'for ((i=0; i<${#gDisk[@]}; ++i))'
    echo 'do'
    echo '  gProtocol=$(diskutil info ${gDisk[i]} |grep -i "Protocol" |sed -e "s|Protocol:||" -e "s| ||g")'
    echo '  is_SDCard=$(diskutil info ${gDisk[i]} |grep -i "Device / Media Name" |grep -i "SD Card")'
    echo '  if [[ ${gProtocol} == *"USB"* ]];'
    echo '    then'
    echo '      gCurrent_Partitions=($(diskutil list ${gDisk[i]} |grep -o "disk[0-9]s[0-9]"))'
    echo '      for ((k=0; k<${#gCurrent_Partitions[@]}; ++k))'
    echo '      do'
    echo '        gConfirm_Mounted=$(diskutil info ${gCurrent_Partitions[k]} |grep -i 'Mounted' |sed -e "s| Mounted:||" -e "s| ||g")'
    echo '        if [[ ${gConfirm_Mounted} == *"Yes"* ]];'
    echo '          then'
    echo '            echo ${gCurrent_Partitions[k]} >> ${gMountPartition}'
    echo '        fi'
    echo '      done'
    echo '      if [ -z ${is_SDCard} ]; then '
    echo '          diskutil eject ${gDisk[i]}'
    echo '      else
    echo '          diskutil unmountDisk ${gDisk[i]}'
    echo '      fi'
    echo '  fi'
    echo 'done'
    echo ''
    # no wlan kext found
    if [ -z $gRTWlan_kext ]; then
        return
    fi
    echo ''
    echo '#'
    echo '# Fix RTLWlanUSB sleep problem credit B1anker & syscl/lighting/Yating Zhou. @PCBeta.'
    echo '#'
    echo ''
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"
    echo 'gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")'
    echo ''
    echo 'if [[ "$gMAC_adr" != 0 ]];'
    echo '  then'
    echo '    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl'
    echo ''
    echo '    if [ ! -f $gRT_Config ];'
    echo '      then'
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*rfoff.rtl)'
    echo '    fi'
    echo ''
    echo "    osascript -e 'quit app \"Wireless Network Utility\"'"
    echo '    echo "1" > "$gRT_Config"'
    echo '    open "/Applications/Wireless Network Utility.app"'
    echo 'fi'                                                                                                                                               
}

#
#--------------------------------------------------------------------------------
#

function _RTLWlanU()
{
    _del ${gUSBWakeScript}
    _del "/etc/syscl.usbfix.wake"

    echo '#!/bin/sh'                                                                                                                                         > "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo '# Added mount Disk for "OS X" (c) syscl/lighting/Yating Zhou.'                                                                                    >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'gMountPartition="/tmp/com.syscl.externalfix"'                                                                                                     >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'cat ${gMountPartition} |xargs -I {} diskutil mount {}'                                                                                            >> "$gUSBWakeScript"
    echo 'rm ${gMountPartition}'                                                                                                                            >> "$gUSBWakeScript"
#   echo 'diskutil list | grep -i "External" | sed -e "s| (external, physical):||" | xargs -I {} diskutil mountDisk {}'                                     >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo '# Fix RTLWlanUSB sleep problem credit B1anker & syscl/lighting/Yating Zhou. @PCBeta.'                                                             >> "$gUSBWakeScript"
    echo '#'                                                                                                                                                >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo "gRTWlan_kext=$(echo $gRTWlan_kext)"                                                                                                               >> "$gUSBWakeScript"
    echo 'gMAC_adr=$(ioreg -rc $gRTWlan_kext | sed -n "/IOMACAddress/ s/.*= <\(.*\)>.*/\1/ p")'                                                             >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo 'if [[ "$gMAC_adr" != 0 ]];'                                                                                                                       >> "$gUSBWakeScript"
    echo '  then'                                                                                                                                           >> "$gUSBWakeScript"
    echo '    gRT_Config="/Applications/Wireless Network Utility.app"/${gMAC_adr}rfoff.rtl'                                                                 >> "$gUSBWakeScript"
    echo ''                                                                                                                                                 >> "$gUSBWakeScript"
    echo '    if [ ! -f $gRT_Config ];'                                                                                                                     >> "$gUSBWakeScript"
    echo '      then'                                                                                                                                       >> "$gUSBWakeScript"
    echo '        gRT_Config=$(ls "/Applications/Wireless Network Utility.app"/*rfoff.rtl)'                                                                 >> "$gUSBWakeScript"
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
        _tidy_exec "sudo mkdir -p ${target_file}" "Create ${target_file}"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _install()
{
    #
    # Check if sleepwatcher has been downloaded
    #
    _checkForExecutableFile
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
    _tidy_exec "_createUSB_Sleep_Script >$gUSBSleepScript" "Generating script to unmount external devices before sleep (c) syscl/lighting/Yating Zhou"

    #
    # Generate script to load RTWlanUSB after wake from sleep.
    #
    if [ -z $gRTWlan_kext ]; then
        _tidy_exec "_RTLWlanU" "Generate script to load RTWlanUSB upon sleep"
    fi

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
