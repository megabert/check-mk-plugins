# Verify the Dumps of automysqlbackup

Verify the operation and the dumps of the script automysqlbackup

The following is checked at the moment:

 * Has automysqlbackup ren at least once?
 * Are the dumps too old?
 * Do the expected dumpfiles exist?
 * Validate the dumpfile(size >0, validate header and footer)
