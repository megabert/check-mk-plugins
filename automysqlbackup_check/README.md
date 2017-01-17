# Verify the Dumps of automysqlbackup

## Systemrequirements

 * Debian or Ubuntu
 * MySQL installed
 * automysqlbackup installed

## What does it do?

Verify the operation and the dumps of the script automysqlbackup

The following is checked at the moment:

 * Has automysqlbackup run at least once?
 * Are the dumps too old?
 * Do the expected dumpfiles exist?
 * Validate the dumpfile(size >0, validate header and footer)

## Installation(Target server only)

 * install lua5.1 + lua5.1-filesystem packages
 * install the cron-job check_amb.cron into /etc/cron.d
 * install the main script automysqlbackup_check to /usr/local/bin/automysqlbackup_check and chmod to executable 
 * install the local plugin local.automysqlbackup to directory /usr/lib/check_mk_agent/local/ and chmod to executable
 * run the check manually once: /usr/local/bin/automysqlbackup_check | tee /var/lib/misc/automysqlbackup_check 
 * rescan all services of the host within check_mk and activate, a new check should now be there

## Usage 

 * If some error is found: The check will report it
 * If the check did not run(failing cron, ...) a missing check would be reported by check_mk
