# ncbkp
A bash script to backup nextcloud data, database and config.

### TODO
* Add support for more database types, right now only supports mysql. Pull requests are welcome. 

### Used rsync syntax explained
* A = preserve ACLs 
* a = archive (recurse dirs, preserve permissions, save symlinks as symlinks, save modification times, groups, owner, device files)
* x = dont cross filesystem boundaries
* P = show progress and keep partially transferred files
* v = verbose
* --delete = will delete locally deleted files at target

