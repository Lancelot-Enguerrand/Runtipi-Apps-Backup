#!/bin/bash
# Usage: ./backup_runtipi_apps.sh [daily|weekly|monthly] [stop|ignore] [path/to/BackupListFile]
# Default parameters are daily stop
 
# Specify your runtipi base path
tipiPath=""
 
# Storage path for the Apps (each app have a folder inside)
backupPath="$tipiPath/backups"
 
# Specify backup retention - Indicate number of backup file to keep for each schedule
dailyRetention=3
weeklyRetention=3
monthlyRetention=3
 
# Default runtipi paths
appsDataPath="$tipiPath/app-data"
appsPath="$tipiPath/apps"
userConfigsPath="$tipiPath/user-config"
 
# Define the temporary directory for the archive creation
archiveCreatingWorkDir="/tmp"
 
# App status - Set defaut value to prevent bug - do not touch
appOrginalStatus='started'
 
# Check for runtipi path value
if [ -z "$tipiPath" ]; then
    echo "Runtipi path not specified"
    echo "Edit path, line 6 in $0"
    exit 1
elif [ -d "$tipiPath" ]; then
    echo "Runtipi path : $tipiPath"
else
    echo "Runtipi path not found : $tipiPath"
    echo "Edit path, line 6 in $0"
    exit 1
fi
 
# Default Parameters
backupTypeDefaultValue='daily'
stopAppDefaultValue='stop'
backupListDefaultValue=$(ls $appsDataPath)
 
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
    *)
        echo "Invalid backup type specified. Use 'daily', 'weekly' or 'monthly'."
        exit 2
        ;;
esac
 
# Should Apps be stopped during backup
stopApp="${2:-$stopAppDefaultValue}"
 
# Should Apps be stopped during backup
refBackupList=$3
if [ -z "$refBackupList" ]; then
    backupList=$backupListDefaultValue
elif [ -f "$refBackupList" ]; then
    backupList=$(cat $refBackupList)
else
    echo "Invalid path for backup list reference file."
    exit 3
fi
 
# List all installed apps
for app in $(ls $appsPath)
do
    # List all apps in backup reference list
    for element in $backupList
    do
        # Check if app is installed
        if [ "$app" = "$element" ]; then
            # Stop the app if it was asked
            if [ "$stopApp" = 'stop' ]; then
                cd $tipiPath
                appStatusCheck=$(docker ps -f name=^/$app$ -q)
                if [ -z "$appStatusCheck" ]; then
                    appOrginalStatus='stopped'
                    echo "App $app is already stopped"
                else
                    appOrginalStatus='started'
                    echo "Stopping $app"
                    ./runtipi-cli app stop $app
                fi
            fi
 
            echo "Preparing $app backup"
            # Set destination app path
            backupAppPath="$backupPath/$app"
            # Create destination directory if doesnt exist
            if [ ! -d "$backupAppPath" ]; then mkdir -p "$backupAppPath"; fi
            # Generate archive name
            backupFileName="$app-$backupType-$(date '+%Y-%m-%d').tar.gz"
 
            # Uncomment next line if you want the archive to be created directly in backup destination
            archiveCreatingWorkDir="$backupAppPath"
 
            # Move to Working Directory for archive creation
            cd $archiveCreatingWorkDir
 
            # Declare source and destination path for directories in archive
            declare -A app_paths=(
                ["$appsPath/$app"]="app"
                ["$appsDataPath/$app"]="app-data"
                ["$userConfigsPath/$app"]="user-config"
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
                else
                    echo "Directory $src does not exist, skipped."
                fi
            done
 
            # Creating archive
            echo "Creating $app archive : $backupFileName"
            tar -czhf "$backupFileName" -C "$tempArchiveDir" .
            # Move archive to Backup storage
            echo "Moving $backupFileName to $backupAppPath"
            mv "$backupFileName" "$backupAppPath"
            # Remove temporary Directory
            echo "Removing temporary files"
            rm -rf "$tempArchiveDir"
 
            # Purge old backups of the same type
            cd "$backupAppPath"
            echo "Purging old $backupType backup for $app"
            ls -t | grep "$app-$backupType-" | tail -n +$((keepLast+1)) | xargs -r rm --
 
            # Restart the app if it was asked to be stopped
            if [ "$stopApp" = 'stop' -a "$appOrginalStatus" = 'started' ]; then
                cd $tipiPath
                echo "Starting $app"
                ./runtipi-cli app start $app
            fi
        fi
    done
done