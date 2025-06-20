#!/bin/bash
#
# Version 2.0 - Need runtipi 4.0 or later
#
# Usage: ./backup_runtipi_apps.sh [daily|weekly|monthly|yearly] [stop|ignore]
# Default parameters are daily stop

# Specify your runtipi base path
runtipiPath=""

# Specify path to you backup reference list (optional)
backupListPath=""

# Storage path for the Apps
backupPath="$runtipiPath/backups"

# Specify backup retention - Number of backup file to keep for each schedule
dailyRetention=3
weeklyRetention=3
monthlyRetention=3
yearlyRetention=3

# Sleep Duration - How many seconds to wait after starting/stopping an apps
sleepDuration=10

# Default runtipi paths
appsDataPath="$runtipiPath/app-data"
appsPath="$runtipiPath/apps"
userConfigsPath="$runtipiPath/user-config"

# Define the temporary directory for the archive creation
archiveCreatingWorkDir="/tmp"

# App status - Set default value to started
appOriginalStatus='started'

# Check for runtipi path value
if [ -z "$runtipiPath" ]; then
    echo "Runtipi path not specified"
    exit 1
elif [ -d "$runtipiPath" ]; then
    echo "Runtipi path : $runtipiPath"
else
    echo "Runtipi path not found : $runtipiPath"
    exit 1
fi

# Default Parameters
backupTypeDefaultValue='daily'
stopAppDefaultValue='stop'

# Define retention policy
backupType="${1:-$backupTypeDefaultValue}"
# Change keepLast to adjust retention policy
case "$backupType" in
    daily)
        keepLast=$dailyRetention
        ;;
    weekly)
        keepLast=$weeklyRetention
        ;;
    monthly)
        keepLast=$monthlyRetention
        ;;
    yearly)
        keepLast=$yearlyRetention
        ;;
    *)
        echo "Invalid backup type specified. Use 'daily', 'weekly', 'monthly' or 'yearly'."
        exit 2
        ;;
esac

# Check Runtipi version
runtipiVersion=$(cat $runtipiPath/VERSION)
runtipiMajorVersion=$(echo $runtipiVersion | cut -d. -f1 VERSION | sed 's/^v//')
if [ "$major_version" -lt 4 ]; then
    echo "Runtipi version is $runtipiVersion, this script require at least v4.0.0"
    exit 4
fi

# Should Apps be stopped during backup
stopApp="${2:-$stopAppDefaultValue}"

# List all appstores
for appStore in $(ls $appsPath)
do
    # Check optional apps reference list
    refBackupList=$backupListPath
    if [ -z "$refBackupList" ]; then
        backupList=$(ls $appsPath/$appStore)
    elif [ -f "$refBackupList" ]; then
        backupList=$(cat $refBackupList)
    else
        echo "Invalid path for backup reference list file."
        exit 3
    fi
    # List all installed apps
    for app in $backupList
    do
        if [ -d $appsPath/$appStore/$app ]; then
            echo "Starting backup apps from $appStore appstore."
            
            # Stop the app if it was asked
            if [ "$stopApp" = 'stop' ]; then
                cd $runtipiPath
                appStatusCheck=$(docker ps -f name=^/$app"_"$appStore -q)
                if [ -z "$appStatusCheck" ]; then
                    appOriginalStatus='stopped'
                    echo "App $app is already stopped"
                else
                    appOriginalStatus='started'
                    echo "Stopping $app"
                    ./runtipi-cli app stop $app:$appStore
                    sleep $sleepDuration
                fi
            fi

            # Set destination app path
            backupAppPath="$backupPath/$appStore/$app"
            # Create destination directory if doesnt exist
            if [ ! -d "$backupAppPath" ]; then mkdir -p "$backupAppPath"; fi
            # Generate archive name
            backupFileName="$app-$backupType-$(date '+%Y-%m-%d').tar.gz"
    
            # Use backup directory as archive file destination
            archiveCreatingWorkDir="$backupAppPath"

            # Move to Working Directory for archive creation
            cd $archiveCreatingWorkDir

            # Declare source and destination path for directories in archive
            declare -A app_paths=(
                ["$appsPath/$appStore/$app"]="app"
                ["$appsDataPath/$appStore/$app"]="app-data"
                ["$userConfigsPath/$appStore/$app"]="user-config"
            )

            echo "Preparing $app files"
            tempArchiveDir=$(mktemp -d)
            for src in "${!app_paths[@]}"; do
                dest="$tempArchiveDir/${app_paths[$src]}"
                echo $dest
                # Ensure the directory exists
                if [ -d "$src" ]; then
                    # Create symbolic link for each directory
                    ln -s "$src" "$dest"
                elif [ $src = "$userConfigsPath/$appStore/$app" ]; then
                    : # echo "No user config for $app"
                else
                    echo "Directory $src does not exist, skipped."
                fi
            done

            # Creating archive
            echo "Creating $app archive : $backupFileName"
            tar -czhf "$backupFileName" -C "$tempArchiveDir" .
            # Remove temporary Directory
            echo "Removing temporary files"
            rm -rf "$tempArchiveDir"

            # Purge old backups of the same type
            cd "$backupAppPath"
            echo "Purging old $backupType backup for $app"
            ls -t | grep "$app-$backupType-" | tail -n +$((keepLast+1)) | xargs -r rm --
    
            # Restart the app if it was asked to be stopped
            if [ "$stopApp" = 'stop' -a "$appOriginalStatus" = 'started' ]; then
                cd $runtipiPath
                echo "Starting $app"
                ./runtipi-cli app start $app:$appStore
                sleep $sleepDuration
            fi
        fi
    done
done
