= Check for automsqlbackup

The check looks if there are any files named ERRORS_*
in the backup directory. If there are: The check fails.

Copy the file check_automysqlbackup to your check_mk local 
dir, normally /usr/lib/check_mk_agent/local, grant
execute priviliges(chmod a+rx ...) and do a full scan
of the host(or issue cmk -II ; cmk -R if that's no problem
for you)
