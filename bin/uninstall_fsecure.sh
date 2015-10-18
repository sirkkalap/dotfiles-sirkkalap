#!/bin/sh

PARTIAL=false
NUKE_CUSTOMIZATIONS=true

while getopts uc opt
do
    case "$opt" in
        u) PARTIAL=true
            ;;
        c) NUKE_CUSTOMIZATIONS=false
            ;;
        \?) echo "Usage: $0"
            exit 1
            ;;
    esac
done

MAGIC=/var/db/.com.f-secure.fsmac.uninstall
LOG="/Library/Logs/F-Secure Mac Protection uninstall.log"

date "+%Y-%m-%d %T: Uninstall script starting: $0 $*" >> "$LOG"
syslog -s -l Critical "Uninstall script starting: $0 $*"

exec 3>&1
exec 1>>"$LOG"
exec 2>>"$LOG"

uname -a

set -x

if [ -r "`dirname $0`/safer_remove_dir" ] ; then
    . "`dirname $0`/safer_remove_dir"
elif [ -r /usr/local/f-secure/bin/safer_remove_dir ] ; then
    . /usr/local/f-secure/bin/safer_remove_dir
else
    echo "Warning: safer_remove_dir not found, using built-in fallback" >&2
    echo "Warning: safer_remove_dir not found, using built-in fallback" >&3
    safer_rmrf() {
        rm -rf "$@"
    }
fi

# Make firewall not block
echo '<firewall block="0"/>' > /usr/local/f-secure/signal/firewall

# This is the old uninstall trigger which is no longer needed.
launchctl remove com.f-secure.fsmac.uninstall
rm -f /Library/LaunchDaemons/com.f-secure.fsmacuninstall.plist
rm -f /var/db/.com.f-secure.fsmac.uninstall

check_error() {
    if test $? -ne 0 ; then
        ERROR=true
        echo "ERROR: $@" >&3
    fi
}

fatalexit() {
    {
        echo
        echo "Uninstallation failed!"
        echo "Please contact support and email them the uninstall log file:"
        echo "$LOG"
    } >&3
    syslog -s -l Critical "Uninstallation failed! Please contact support and email them the uninstall log file: $LOG"
    exit 1
}

####
#
# Main()
#
date "+%Y-%m-%d %H:%M:%S Uninstalling FS Mac:"

if [ "`id -u`" != "0" ] ; then
    echo "Need root permissions to perform uninstallation. Run the command as" >&3
    echo "sudo $0" >&3
    exit 1
fi
date "+%Y-%m-%d %H:%M:%S checkpoint 1"
echo "Uninstalling..." >&3

id -a

ERROR=false

ps axo "user,pid,comm" |
        awk '$1 != "root" && /loginwindow/ {printf "user=%s pid=%s\n", $1, $2}' |
                while read e ; do
                        eval $e
                        errors=`launchctl bsexec $pid su -l $user -c "launchctl unload -S Aqua /Library/LaunchAgents/com.f-secure.gui.plist" 2>&1`
                        if [ -n "$errors" ]; then
                            echo "$errors"
                            echo "Unloading launch agents is not fatal, continuing..."
                        fi
                        errors=`launchctl bsexec $pid su -l $user -c "launchctl unload /Library/LaunchAgents/com.f-secure.trasher.plist" 2>&1`
                        if [ -n "$errors" ]; then
                            echo "$errors"
                            echo "Unloading launch agents is not fatal, continuing..."
                        fi
                        errors=`launchctl bsexec $pid su -l $user -c "launchctl remove com.f-secure.fsmac.subsvars" 2>&1`
                        if [ -n "$errors" ]; then
                            echo "$errors"
                            echo "Unloading old launch agent (subsvars) is not fatal, continuing..."
                        fi
                done
check_error "Failed to unload GUI"
date "+%Y-%m-%d %H:%M:%S checkpoint 2"
echo "LaunchAgents unloaded" >&3

if killall fscuif; then
    sleep 2
    if killall -0 fscuif ; then
        killall -9 fscuif
    fi
fi
date "+%Y-%m-%d %H:%M:%S checkpoint 3"
echo "GUI killed" >&3

/usr/local/f-secure/bin/loginitem - "`find /Applications -maxdepth 2 -name 'F-Secure Mac Protection.app'|head -1`"

/bin/rm -f "/Library/LaunchAgents/com.f-secure.gui.plist"
rm -f /Library/LaunchAgents/com.f-secure.fsmac.subsvars.plist
/bin/rm -f "/Library/LaunchAgents/com.f-secure.trasher.plist"

# NOTE: uninstall is not listed in labels because if we unloaded it
# launchd would kill this script
daemon_labels="com.f-secure.fsavd.dbver_update com.f-secure.clstate-dbupdate com.f-secure.clstate-periodic com.f-secure.fsmac.fsupdated com.f-secure.fsmac.firewall com.f-secure.fsavd.dbhelper com.f-secure.fsavd com.f-secure.aua"
daemon_plists="com.f-secure.fsavd.dbver_update.plist com.f-secure.clstate-dbupdate.plist com.f-secure.clstate-periodic.plist com.f-secure.fsmac.fsupdated.plist com.f-secure.fsmac.firewall.plist com.f-secure.fsavd.dbhelper.plist com.f-secure.fsavd.plist com.f-secure.aua.plist com.f-secure.fsmacuninstall.plist"

for daemon in $daemon_labels; do
    echo "Stopping $daemon"
    if [ "$daemon" = "com.f-secure.aua" ]; then
        # Wait for dbupdate to finish before shutting down AUA.
        # Otherwise dbupdate will run fsav --copyright --print-license that
        # will delay for a half a minute or so before giving up trying to
        # connect to AUA that is no longer running.
        waiting=30
        while killall -0 dbupdate && [ $waiting -gt 0 ]; do
            echo "dbupdate still running, waiting for it to exit"
            sleep 1
            waiting=$(($waiting - 1))
        done
        if killall -0 dbupdate; then
            echo "dbupdate is still running, falling back to kill -9"
            killall -9 dbupdate
            sleep 1
        fi
    fi
    launchctl remove $daemon
done

for plist in $daemon_plists; do
    rm -f /Library/LaunchDaemons/$plist
done

date "+%Y-%m-%d %H:%M:%S checkpoint 4"
echo "LaunchDaemons unloaded" >&3

# Remove infections.db for all users
/bin/rm -f /Users/*/Library/Application\ Support/F-Secure/Mac\ Protection/infections.db
# Remove F-Secure directories, only if they're empty
/bin/rmdir /Users/*/Library/Application\ Support/F-Secure/Mac\ Protection
/bin/rmdir /Users/*/Library/Application\ Support/F-Secure

if ! ${PARTIAL} ; then
    /bin/rm -f /Users/*/Library/Preferences/com.f-secure.F-Secure\ ControlLayer-*.plist
fi
date "+%Y-%m-%d %H:%M:%S checkpoint 5"
echo "Removing in /Applications" >&3

remove_app() {
    app="$1"
    bundleid="$2"
    find /Applications -maxdepth 2 -type d -name "$app" | while read app_path; do
        if [ -z "$app_path" ]; then
            echo "$app was not found. Maybe someone (re)moved it?" >&3
            continue
        fi
        if grep "<string>${bundleid}</string>" "${app_path}/Contents/Info.plist"; then
            :
        else
            echo "$app_path found, but bundle id does not match $bundleid" >&3
            continue
        fi
        if [ "$app_path" = "/Applications" -o "$app_path" = "/" ]; then
            echo "Something is wrong! Installation folder was detected as $app_path" >&3
        else
            safer_rmrf "$app_path"
        fi
        app_parent=`dirname "$app_path"`
        if [ "$app_parent" = "/Applications" -o "$app_parent" = "/" ]; then
            echo "app parent dir $app_parent, not removing" >&3
        else
            rmdir "$app_parent"
        fi
    done
}

remove_app 'F-Secure Mac Protection.app' 'com.f-secure.fsmac.gui'
remove_app 'F-Secure Support Tool.app' 'com.f-secure.fsmac.gui.fsdiag'
remove_app 'uninstall.app' 'com.f-secure.fsmac.gui.uninstall'

date "+%Y-%m-%d %H:%M:%S checkpoint 6"
echo "Removing daemons and command line tools" >&3

if ${PARTIAL} ; then
    /bin/sh -c '/usr/bin/find -d /usr/local/f-secure/ -type f -or -type l |  /usr/bin/grep -v fsaua/var | while read file ; do /bin/rm -v "$file"; done'
    /bin/sh -c '/usr/bin/find -d /usr/local/f-secure/ -type d |  /usr/bin/grep -v fsaua/var | while read dir ; do /bin/rmdir "$dir"; done'
else
    safer_rmrf "/usr/local/f-secure/"
    dscl . -delete /Groups/fsc
    dscl . -delete /Users/fsaua
fi

safer_rmrf /usr/local/f-secure/fsaua/var/handlers

/bin/rm -f /usr/local/bin/dbupdate /usr/local/bin/fsav


date "+%Y-%m-%d %H:%M:%S checkpoint 7"
echo "Removing driver" >&3

waiting=10
while killall -0 fsavd && [ $waiting -gt 0 ]; do
    echo "fsavd still running, waiting for it to exit"
    sleep 1
    waiting=`expr $waiting - 1`
done
if killall -0 fsavd; then
    echo "fsavd is still running, falling back to kill -9"
    killall -9 fsavd
    sleep 1
fi

if kextstat -b com.f-secure.kext.fsauth | grep -q com.f-secure.kext.fsauth; then
    kextunload -b com.f-secure.kext.fsauth
    check_error "Failed to remove kernel extension fsauth"
fi
safer_rmrf "/System/Library/Extensions/fsauth.kext"

if $NUKE_CUSTOMIZATIONS ; then
    echo "Removing customizations" >&3

    safer_rmrf "/Library/F-Secure/fsmac"

    pkgutil --pkgs | grep ^com.f-secure.fsmac | grep customiz | xargs -n 1 pkgutil --forget
    ls -d /Library/Receipts/com.f-secure.fsmac* | grep customiz | xargs rm -rf
fi

date "+%Y-%m-%d %H:%M:%S checkpoint 8"
echo "Removing receipts" >&3
echo `pkgutil --pkgs | grep ^com.f-secure.fsmac | grep -v customiz` com.f-secure.fssp.pkg com.f-secure.agents-and-daemons.pkg com.f-secure.aua.pkg | xargs -n 1 pkgutil --forget

ls -d /Library/Receipts/com.f-secure.fsmac* | grep -v customiz | xargs rm -rf
rm -rf /Library/Receipts/com.f-secure.fssp.*
rm -rf /Library/Receipts/com.f-secure.aua.*
rm -rf /Library/Receipts/com.f-secure.fsauth.*

rm -rf /tmp/.com.f-secure.fsav
rm -f /tmp/ods-*.db
rm -f /tmp/ods-*.db.real
rm -f /Users/*/Library/Application\ Support/F-Secure/Mac\ Protection/infections.db
rm -f /var/log/fsavd.log
rm -rf /Library/Caches/com.f-secure.MacProtection.*

echo >&3

if ! ${PARTIAL} ; then
    safer_rmrf /Library/F-Secure/fsmac
fi

# Empty the contents of the magic file to prevent further accidental uninstalls.
echo >$MAGIC

date "+%Y-%m-%d %H:%M:%S checkpoint 9"

if $ERROR ; then
    echo "Some errors were encountered during uninstallation." >&3
    echo "Please email uninstall log file ($LOG) " >&3
    echo "to address <mac-tp@f-secure.com>" >&3
    echo "Please reboot before installing F-Secure Mac Protection again" >&3
    rc=1
else
    echo "Uninstallation complete." >&3
    syslog -s -l Critical "Uninstallation complete."
    rc=0
fi
echo $rc > /tmp/.com.f-secure.fsmac.uninstall-rc
date "+%Y-%m-%d %H:%M:%S checkpoint 10"
exit $rc
