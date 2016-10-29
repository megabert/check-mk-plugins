= Check Postfix Processed Mails

This plugin examines the postfix log file and counts
the send state(sent/bounced/deferred). The default 
inspection period is the last 3600 seconds. This can
be adjusted. 

The Check is based on lua - a tiny scriping language
which needs to be installed. 

The check takes a bit longer at the first run. But
beginning with the second run it's blazing fast, since
it stores all already read mail ids in separate file.
The postfix-log also is read from the end of the file
backwards, which also improves speed. 

The size of the logfile should not matter, it should
be able to handle files of several GBs in size.
