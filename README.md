# ⛺️ Runtipi Apps Backup Script 💾
Script for backing up runtipi apps data with retention policy.
> [!WARNING]  
> Runtipi v4 and further needs script v2

## How to use ?
I suggest to refer directly into runtipi official guides here : [runtipi.io/docs](https://runtipi.io/docs/guides/auto-backup-apps)  
Thanks to [Stavros](https://github.com/steveiliop56) for documentation and publishing. 🤩

### ✍️ Define values
###### ⛺️ runtipi path
You need to set your `runtipiPath` to point to your actual runtipi path.
###### 🗓 retention
Retention policy is defined in script and is 3 by default, you can change it to your own convenience :
```bash
dailyRetention=3
weeklyRetention=3
monthlyRetention=3
yearlyRetention=3
```
This define the number of files that will be kept for each type of backup.
### ⚙️ Arguments

| Accepted Values                     | Description                                                                                                        | Default | Required |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| `daily`,`weekly`,`monthly`,`yearly` | Set the name of the final backup, for example if you use `daily` the backup name will be `myapp-daily-date.tar.gz` | `daily` | no       |
| `stop`,`ignore`                     | Stop the app before backing up or backup anyway.                                                                   | `stop`  | no       |

[deprecated]: <>  (| `path`                     | Specify a path to a file describing what apps you want to backup, each app id in a new line.                       | `none`  | no       |)

### ⏰ Cron example 
```bash
0 2 * * * /path/to/runtipi/scripts/backup_runtipi_apps.sh daily
0 3 * * 1 /path/to/runtipi/scripts/backup_runtipi_apps.sh weekly
0 4 1 * * /path/to/runtipi/scripts/backup_runtipi_apps.sh monthly
0 5 1 1 * /path/to/runtipi/scripts/backup_runtipi_apps.sh yearly
```

## ✨ How to restore an app ?
Simply use the restore functionnality from Runtipi WebUI.  
*My Apps* &rarr; *AppName* &rarr; *Backups*  
Choose your desired backup and select **Restore**

## 🤔 Considered enhancements
1. Restoration Script : It was initially planned but built-in runtipi backup functionnality made it feel unnecessary.
2. Check if the restored app has been stopped correctly
3. Reference List to choose which to backup has been removed but it could be replaced with a whitelist/blacklist system
4. Using Runtipi built-in functionalities : Runtipi is growing and may add backup support in runtipi-cli, it could probably even make this script obsolete in the future.
