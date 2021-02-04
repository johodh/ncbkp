# ncbkp
backup nextcloud data, database and config

### Used rsync syntax explained
A = preserve ACLs 
a = archive (recurse dirs, preserve permissions, save symlinks as symlinks, save modification times, groups, owner, device files)
x = dont cross filesystem boundaries
P = show progress and keep partially transferred files
v = verbose
--delete = will delete locally deleted files at target

