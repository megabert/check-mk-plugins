# Hostgroup without acknowledged Problems

This extension creates a new view. It's derived from the "Hostgroup Summary" an only filters out all acknowledged services and hosts, so you can focus on the new problems. Developed and tested on Check_MK Raw Edition 1.2.8p11

## Installation

Copy the 2 files into your OMD site directory in folder 

```
/omd/sites/YOURSITE/local/share/check_mk/web/plugins/views
```

Reload Check_MK Website. The new view should now be available in the Dashlet "Views" under "Host Groups"

