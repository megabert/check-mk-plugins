# check_ipmi_remote

Checks a remote IPMI-Device if reachable via ipmi-protocol(ipmitool) or 
do some fuzzy checking if a webinterface of the IPMI-Device 
is up if the command line client gets no connection.

## Installation

- put the script check_ipmi_remote into your local nagios plugins
folder /omd/sites/YOURSITE/local/lib/nagios/plugins
- put your ipmi password into the script
- add execute permissions
- create a folder within wato where you create all ipmi-devices in
- create a rule for a "classical nagios check" like this one: $USER2$/check_ipmi_remote $HOSTADDRESS$
  on that wato-folder

