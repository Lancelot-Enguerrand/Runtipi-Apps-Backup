# ⛺️ Runtipi Apps Backup Script 💾
Script for backing up runtipi apps data with retention policy.

## How to use ?
I suggest to refer directly into runtipi official guides here : [runtipi.io/docs](https://runtipi.io/docs/guides/auto-backup-apps)  
Thanks to [Stavros](https://github.com/steveiliop56) for documentation and publishing. 🤩

### ✍️ Define values
###### ⛺️ runtipi path
You need to set your `tipiPath` to point to your actual runtipi path.
###### 🗓 retention
Retention policy is defined in script and is 3 by default, you can change it to your own convenience :
```bash
dailyRetention=3
weeklyRetention=3
monthlyRetention=3
```
This define the number of files that will be kept for each type of backup.
### ⚙️ Arguments

| Accepted Values            | Description                                                                                                        | Default | Required |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| `monthly`,`weekly`,`daily` | Set the name of the final backup, for example if you use `daily` the backup name will be `myapp-daily-date.tar.gz` | `daily` | no       |
| `stop`,`ignore`            | Stop the app before backing up or backup anyway.                                                                   | `stop`  | no       |
| `path`                     | Specify a path to a file describing what apps you want to backup, each app id in a new line.                       | `none`  | no       |

### ⏰ Cron example 
```bash
0 2 * * 0 /path/to/runtipi/scripts/backup-apps.sh daily
0 3 * * 0 /path/to/runtipi/scripts/backup-apps.sh weekly
0 4 * * 0 /path/to/runtipi/scripts/backup-apps.sh monthly
```

## ✨ How to restore an app ?
Simply use the restore functionnality from Runtipi WebUI.  
*My Apps* &rarr; *AppName* &rarr; *Backups*  
Choose your desired backup and select **Restore**

## 🤔 Considered enhancements
1. Restoration Script : It was initially planned but built-in runtipi backup functionnality made it feel unnecessary.
2. Using Runtipi built-in functionalities : Runtipi is growing and may add backup support in runtipi-cli, it could probably even make this script obsolete in the future.
