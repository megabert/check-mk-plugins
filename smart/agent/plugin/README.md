# Addition for Smart Data for Adaptec RAID controllers

Normally Adaptec RAID Controllers should not report SMART status via the
SCSI-Generic Device. Some controllers does not do that and only reveal
the SMART data via "arcconf getstartstats ...".

So this plugin aacraid.smart does exactly that. It calls arcconf getsmartstats 
for every controller and transformes the xml data into standard SMART lines 
that checkmk.smart expects.

## Requirements

arcconf version 3.0 is installed in path

## Installation

- copy aaraid.smart to /usr/sbin and make it executable
- install the following cronjobs which will do the necessary tasks in background

```
@reboot		root	/usr/sbin/aacraid.smart smart_scan
@reboot		root	/usr/sbin/aacraid.smart controller_scan
*/15 * * * *	root	/usr/sbin/aacraid.smart smart_scan
5 1 * * *	root	/usr/sbin/aacraid.smart controller_scan
```

- add the following line at the end of the smart plugin of check_mk 

```
[ -x /usr/sbin/aacraid.smart ] && /usr/sbin/aacraid.smart smart_display
```

# Patch for LSI/Megaraid Controllers

The patch provides SMART Data for Disks behind a LSI/Megaraid Adapter.
