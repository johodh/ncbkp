# ncbkp
A bash script to automate backup of my Nextcloud instance data, database and config. Intended for use with systemd/Timers. Note that this script puts Nextcloud in maintenance mode, making it inaccessible to users during backup. Backup might take a while depending on the size of your instance and connection speed if target is remote.  

Method adapted from here:
https://docs.nextcloud.com/server/20/admin_manual/maintenance/backup.html

### TODO
* Add support for more database types, right now only supports mysql. Pull requests are welcome. 

### rsync syntax explained
* A = preserve ACLs 
* a = archive (recurse dirs, preserve permissions, save symlinks as symlinks, save modification times, groups, owner, device files)
* x = dont cross filesystem boundaries
* P = show progress and keep partially transferred files
* v = verbose
* --delete = will delete locally deleted files at target

