# local raid controller check for windows

This is a local check for raid controllers for Windows, which can be queried using the ssacli.exe from HP.

# Prerequisites

- an installed Check-MK Agent on the Windows System to be monitored
- ssacli.exe installed from HP Website

# Installation

- create directory C:\program files (x86)\monitoring
- create directory C:\program files (x86)\monitoring\bin
- create directory C:\program files (x86)\monitoring\data
- place place ssacli.exe into the bin directory from above
- place ssacli_checkmk.pl into the bin directory from above
- place ssacli_local_wrapper into the "local" directory of the check_mk agent:
	* up to Check-MK Agent 1.5: C:\program files (x86)\checkmk\local
	* from Check-MK Agent 1.6 onwards: C:\ProgramData\checkmk\agent\local
- install strawberry perl from: https://strawberryperl.com
- get nssm.exe from http://nssm.cc (Non-Sucking Service manager)
- Install the perl script as a service with nssm
	- open a cmd.exe with admin privileges
	- cd to the directory containing nssm.exe
	- run: "nssm install hpraidcheck"
	- gui opens
	- some important settings:
		- run service as local system account(no desktop interaction)
		- application path: c:\strawberry\perl\bin\perl.exe
		- arguments: "C:\program files (x86)\monitoring\bin\ssacli_checkmk.pl"
		  (the quotes have to be there!)
	- start the service manually with: "net start hpraidcheck"

- The installation is now finished and you should see your raid status text in the data directory.
- A log file is also in the data directory in case some errors occur.
