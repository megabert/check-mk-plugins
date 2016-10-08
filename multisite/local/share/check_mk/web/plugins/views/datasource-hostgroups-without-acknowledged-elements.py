
# a quick hack(tm)

def dontspoilthenamespace_get_ack_hg_data(columns, query, only_sites, limit, all_active_filters):
	datasource = multisite_datasources["hostgroups-without-acknowledged-elements"].copy()
	datasource["table"] = "hostgroups"
	hostgroups   = query_data(datasource, columns, [], query, only_sites, limit)
	service_data = query_data(
				multisite_datasources["services-without-acknowledged-elements"],
				["display_name", "host_name","host_groups","display_name","state","state_type","acknowledged"],
				[],"",only_sites,limit)
	host_data = query_data( multisite_datasources["hosts-without-acknowledged-elements"],
				["host_name", "host_groups","state","state_type","acknowledged"],
				[],"",only_sites,limit)

	svc_const  = { 1 : "warn", 2 : "crit"    }
	host_const = { 1 : "down", 2 : "unreach" } 
	ack={}
	for svc in service_data:	
		for hg in svc["host_groups"]:
			if not hg in ack: 
				ack[hg]={}
			if not "services" in ack[hg]: 
				ack[hg]["services"]={}
			if not svc["state"] in ack[hg]["services"]: 
				ack[hg]["services"][svc["state"]]=1
			else:
				ack[hg]["services"][svc["state"]]=ack[hg]["services"][svc["state"]]+1
	for host in host_data:	
		for hg in host["host_groups"]:
			if not hg in ack: 
				ack[hg]={}
			if not "hosts" in ack[hg]: 
				ack[hg]["hosts"]={}
			if not host["state"] in ack[hg]["hosts"]: 
				ack[hg]["hosts"][host["state"]]=1
			else:
				ack[hg]["hosts"][host["state"]]=ack[hg]["hosts"][host["state"]]+1

	ind=0
	for hg in hostgroups:
		hg_name=hg["hostgroup_name"]
		if hg_name in ack:
			if "services" in ack[hg_name]:
				for counter in ack[hg_name]["services"]:
					if counter in svc_const:
						k = "hostgroup_num_services_"+svc_const[counter]
						hostgroups[ind][k] = hostgroups[ind][k] - ack[hg_name]["services"][counter] 
			if "hosts" in ack[hg_name]:
				for counter in ack[hg_name]["hosts"]:
					if counter in host_const:
						k = "hostgroup_num_hosts_"+host_const[counter]
						hostgroups[ind][k] = hostgroups[ind][k] - ack[hg_name]["hosts"][counter] 
		ind=ind+1

	return hostgroups

multisite_datasources["services-without-acknowledged-elements"] = {
    "title"   : _("Services"),
    "table"   : "services",
    "add_headers" : "Filter: state =~ 0\nFilter: acknowledged = 1\n",
    "infos"   : [ "service" ],
    "keys"    : [ "display_name" ],
    "idkeys"  : [ "site", "display_name" ],
}

multisite_datasources["hosts-without-acknowledged-elements"] = {
    "title"   : _("Hosts"),
    "table"   : "hosts",
    "add_headers" : "Filter: state =~ 0\nFilter: acknowledged = 1\n",
    "infos"   : [ "host" ],
    "keys"    : [ "host_name" ],
    "idkeys"  : [ "site", "hostgroup_name" ],
}

multisite_datasources["hostgroups-without-acknowledged-elements"] = {
    "title"   : _("Hostgroups"),
    "table"   : lambda columns,query,only_sites,limit,all_active_filters: dontspoilthenamespace_get_ack_hg_data(columns,query,only_sites,limit,all_active_filters),
    "infos"   : [ "hostgroup" ],
    "keys"    : [ "hostgroup_name" ],
    "idkeys"  : [ "site", "hostgroup_name" ],
}
