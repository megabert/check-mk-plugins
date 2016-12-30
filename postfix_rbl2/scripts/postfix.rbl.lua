#!/usr/bin/env lua

CMD={
        ["IFCONFIG"]="ifconfig",
        ["IP"]="ip",
        ["POSTCONF"]="postconf",
        ["NETSTAT"]="netstat",
        ["SS"]="ss"
}

OUTPUT_DIR              = "/var/lib/blacklistcheck"
-- VALIDITY_FULL                = 86400
-- VALIDITY_SHORT               = 1800
OUTPUT_FILE_FULL        = OUTPUT_DIR .. "/full"
OUTPUT_FILE_SHORT       = OUTPUT_DIR .. "/short"

function get_process_output(cmd)

        local handle,err = io.popen("LC_ALL=C ".. cmd,"r");
        if(handle) then
                return handle:read("*all")
        else
                return nil,err
        end
end

function check_command(cmd) 
        return os.execute("which "..cmd.." >/dev/null")==0;
end

function find_ipv4_in_ip_output() 

        local ips = {}

        if(not check_command(CMD["IP"])) then return end

        local text =(get_process_output("/sbin/ip addr show"))
        text:gsub("inet ([0-9][0-9]?[0-9]?%.([0-9][0-9]?[0-9]?)%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?)/%d+",
                function(ip,b) 
                        b=tonumber(b)
                        if (not ( 
                                        ip:match("^192.168")
                                or      ip == "127.0.0.1"
                                or      ip:match("^10%.")
                                or      ( ip:match("^172") and ( b >= 16 and b <= 31))
                                )) then
                        ips[#ips+1]=ip
                        end
                end)
        return ips

end

function find_ipv4_in_ifconfig_output() 

        local ips = {}

        if(not check_command(CMD["IFCONFIG"])) then return end

        local text =(get_process_output("/sbin/ifconfig"))
        text:gsub("inet addr:([0-9][0-9]?[0-9]?%.([0-9][0-9]?[0-9]?)%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?)",
                function(ip,b) 
                        b=tonumber(b)
                        if (not ( 
                                        ip:match("^192%.168")
                                or      ip:match("^127%.")
                                or      ip:match("^10%.")
                                or      ( ip:match("^172%.") and ( b >= 16 and b <= 31))
                                )) then
                        ips[#ips+1]=ip
                        end
                end)
        return ips
end


function get_all_public_ips()

        local ips = find_ipv4_in_ip_output() or find_ipv4_in_ifconfig_output()
        return ips
end

function get_postfix_smtp_bind_ip()

        local bind_address = nil
        if(not check_command(CMD["POSTCONF"])) then return end
        local text = (get_process_output("postconf"))
        for line in text:gmatch(".*$") do
                line:gsub("smtp_bind_address = ([0-9][0-9]?[0-9]?%.([0-9][0-9]?[0-9]?)%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?)",
                function(ip) bind_address=ip end)
        end
        if(bind_address) then return {bind_address} end 
end

function get_listen_ips_ss()

        if(not check_command(CMD["SS"])) then return end

        local ips={}
        local all_ips=nil

        local text = get_process_output("ss -nlt")
        text:gsub("([0-9%.%*]+):([0-9]+)",
                function(ip,port) 
                if(port == "465" or port == "25" or port == "587") then
                        if(ip=="*") then 
                                all_ips=true 
                        else
                                ips[#ips+1]=ip
                        end
                end
                end)
        if(all_ips) then
                return get_all_public_ips()
        else
                return ips
        end
end

function get_listen_ips_netstat()

        if(not check_command(CMD["NETSTAT"])) then return end

        local ips={}
        local all_ips=nil

        local text = get_process_output("netstat -nlt")
        text:gsub("([0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?):([0-9]+)",
                function(ip,port) 
                if(port == "465" or port == "25" or port == "587") then
                        if(ip=="0.0.0.0") then 
                                all_ips=true 
                        else
                                ips[#ips+1]=ip
                        end
                end
                end)
        if(all_ips) then
                return get_all_public_ips()
        else
                return ips
        end
end

function get_postfix_bind_ips() 

        local bind_ips = get_listen_ips_ss()
        return bind_ips

end

function get_blacklist_check_ips()
        return get_postfix_smtp_bind_ip() or get_postfix_bind_ips() or get_all_public_ips()
end

function blacklist_check_all(ips,check_servers)
        res = {}
        for ind1,ip in ipairs(ips) do
                listings=""
                for ind2,check_server in ipairs(check_servers) do
                        if(ip_is_blacklisted(ip,check_server)) then
                        listings=((listings=="") and check_server) or (listings..","..check_server)
                        end
                end
                if(listings=="") then
                        res[ip]={true,""}
                else
                        res[ip]={false,listings}
                end
        end 
        return res
end

function ip_is_blacklisted(ip,check_server)
        local rev_ip
        ip:gsub("([0-9][0-9]?[0-9]?)%.([0-9][0-9]?[0-9]?)%.([0-9][0-9]?[0-9]?)%.([0-9][0-9]?[0-9]?)",
                function(ip1,ip2,ip3,ip4) 
                        rev_ip=string.format("%s.%s.%s.%s",ip4,ip3,ip2,ip1)
                end)
        local res = get_process_output("host "..rev_ip.."."..check_server)
        -- if (res:match("has address")) then print (ip .. " listed at " .. check_server) end
        return (res:match("has address 127.0.0") and true or false)

end

function directory_exists( path )
  if type( path ) ~= "string" then return false end

  local response = os.execute( "cd " .. path .. " 2>/dev/null")
  if response == 0 then
    return true
  end
  return false
end

function init() 

        local res = directory_exists(OUTPUT_DIR) or os.execute("mkdir -p "..OUTPUT_DIR)
	local error
	
        if(not (check_command(CMD["SS"]) or check_command(CMD["NETSTAT"]) )) then 
		print("ERROR: Neither netstat nor ss are found in path, need at least one of them")
		error=1
	end

        if(not (check_command(CMD["IP"]) or check_command(CMD["IFCONFIG"]) )) then 
		print("ERROR: Neither ifconfig nor ip are found in path, need at least one of them")
		error=1
	end

	if(error) then
		os.exit(1)
	end

end

local blacklistcheck_servers = {

"aspews.ext.sorbs.net", 
"b.barracudacentral.org",
"bl.blocklist.de",
"bl.spamcop.net",
"zen.spamhaus.org",
"spam.dnsbl.sorbs.net",
"dnsbl.sorbs.net",
"ix.dnsbl.manitu.net"

}

local blacklistcheck_servers_all = {

'bl.dronebl.org',
'0spam.fusionzero.com',
'0spam-killlist.fusionzero.com',
'0spamurl.fusionzero.com',
'uribl.zeustracker.abuse.ch',
'ipbl.zeustracker.abuse.ch',
'rbl.abuse.ro',
'uribl.abuse.ro',
'spam.dnsbl.anonmails.de',
'dnsbl.anticaptcha.net',
'orvedb.aupads.org',
'rsbl.aupads.org',
'l1.apews.org',
'aspews.ext.sorbs.net',
'dnsbl.aspnet.hu',
'dnsbl.aspnet.hu',
'b.barracudacentral.org',
'bb.barracudacentral.org',
'list.bbfh.org',
'l1.bbfh.ext.sorbs.net',
'l2.bbfh.ext.sorbs.net',
'l3.bbfh.ext.sorbs.net',
'l4.bbfh.ext.sorbs.net',
'netscan.rbl.blockedservers.com',
'rbl.blockedservers.com',
'spam.rbl.blockedservers.com',
'list.blogspambl.com',
'bsb.empty.us',
'bsb.empty.us',
'bsb.spamlookup.net',
'bsb.spamlookup.net',
'blacklist.sci.kun.nl',
'cbl.anti-spam.org.cn',
'cblplus.anti-spam.org.cn',
'cblless.anti-spam.org.cn',
'cdl.anti-spam.org.cn',
'cbl.abuseat.org',
'bogons.cymru.com',
'v4.fullbogons.cymru.com',
'torexit.dan.me.uk',
'ex.dnsbl.org',
'in.dnsbl.org',
'rbl.dns-servicios.com',
'dnsbl.net.ua',
'dnsbl.othello.ch',
'dnsbl.rv-soft.info',
'dnsblchile.org',
'dnsrbl.org',
'vote.drbl.caravan.ru',
'work.drbl.caravan.ru',
'vote.drbldf.dsbl.ru',
'work.drbldf.dsbl.ru',
'vote.drbl.gremlin.ru',
'work.drbl.gremlin.ru',
'bl.drmx.org',
'dnsbl.dronebl.org',
'rbl.efnet.org',
'rbl.efnetrbl.org',
'tor.efnet.org',
'bl.emailbasura.org',
'rbl.fasthosts.co.uk',
'fnrbl.fast.net',
'hil.habeas.com',
'dnsbl.cobion.com',
'lookup.dnsbl.iip.lu',
'spamrbl.imp.ch',
'wormrbl.imp.ch',
'dnsbl.inps.de',
'rbl.interserver.net',
'mail-abuse.blacklist.jippg.org',
'dnsbl.justspam.org',
'dnsbl.kempt.net',
'spamlist.or.kr',
'bl.konstant.no',
'relays.bl.kundenserver.de',
'spamguard.leadmon.net',
'rbl.lugh.ch',
'dnsbl.madavi.de',
'service.mailblacklist.com',
'service.mailblacklist.com',
'bl.mailspike.net',
'z.mailspike.net',
'bl.mav.com.br',
'cidr.bl.mcafee.com',
'rbl.megarbl.net',
'combined.rbl.msrbl.net',
'images.rbl.msrbl.net',
'phishing.rbl.msrbl.net',
'spam.rbl.msrbl.net',
'virus.rbl.msrbl.net',
'web.rbl.msrbl.net',
'relays.nether.net',
'unsure.nether.net',
'ix.dnsbl.manitu.net',
'no-more-funn.moensted.dk',
'dyn.nszones.com',
'sbl.nszones.com',
'bl.nszones.com',
'ubl.nszones.com',
'dnsbl.openresolvers.org',
'spam.pedantic.org',
'pofon.foobar.hu',
'uribl.pofon.foobar.hu',
'dnsbl.proxybl.org',
'psbl.surriel.com',
'all.rbl.jp',
'dyndns.rbl.jp',
'short.rbl.jp',
'url.rbl.jp',
'virus.rbl.jp',
'rbl.schulte.org',
'rbl.talkactive.net',
'access.redhawk.org',
'abuse.rfc-clueless.org',
'bogusmx.rfc-clueless.org',
'dsn.rfc-clueless.org',
'elitist.rfc-clueless.org',
'fulldom.rfc-clueless.org',
'postmaster.rfc-clueless.org',
'whois.rfc-clueless.org',
'dnsbl.rizon.net',
'dynip.rothen.com',
'dnsbl.rymsho.ru',
'rhsbl.rymsho.ru',
'all.s5h.net',
'public.sarbl.org',
'rhsbl.scientificspam.net',
'bl.scientificspam.net',
'tor.dnsbl.sectoor.de',
'exitnodes.tor.dnsbl.sectoor.de',
'bl.score.senderscore.com',
'singular.ttk.pte.hu',
'dnsbl.sorbs.net',
'problems.dnsbl.sorbs.net',
'proxies.dnsbl.sorbs.net',
'relays.dnsbl.sorbs.net',
'safe.dnsbl.sorbs.net',
'nomail.rhsbl.sorbs.net',
'badconf.rhsbl.sorbs.net',
'dul.dnsbl.sorbs.net',
'zombie.dnsbl.sorbs.net',
'block.dnsbl.sorbs.net',
'escalations.dnsbl.sorbs.net',
'http.dnsbl.sorbs.net',
'misc.dnsbl.sorbs.net',
'smtp.dnsbl.sorbs.net',
'socks.dnsbl.sorbs.net',
'rhsbl.sorbs.net',
'spam.dnsbl.sorbs.net',
'recent.spam.dnsbl.sorbs.net',
'new.spam.dnsbl.sorbs.net',
'old.spam.dnsbl.sorbs.net',
'web.dnsbl.sorbs.net',
'korea.services.net',
'backscatter.spameatingmonkey.net',
'badnets.spameatingmonkey.net',
'bl.spameatingmonkey.net',
'fresh.spameatingmonkey.net',
'fresh10.spameatingmonkey.net',
'fresh15.spameatingmonkey.net',
'netbl.spameatingmonkey.net',
'uribl.spameatingmonkey.net',
'urired.spameatingmonkey.net',
'singlebl.spamgrouper.com',
'netblockbl.spamgrouper.to',
'bl.spamcannibal.org',
'dnsbl.spam-champuru.livedoor.com',
'bl.spamcop.net',
'pbl.spamhaus.org',
'sbl.spamhaus.org',
'sbl-xbl.spamhaus.org',
'xbl.spamhaus.org',
'zen.spamhaus.org',
'feb.spamlab.com',
'rbl.spamlab.com',
'all.spamrats.com',
'dyna.spamrats.com',
'noptr.spamrats.com',
'spam.spamrats.com',
'spamsources.fabel.dk',
'bl.spamstinks.com',
'badhost.stopspam.org',
'block.stopspam.org',
'dnsbl.stopspam.org',
'dul.pacifier.net',
'bl.suomispam.net',
'gl.suomispam.net',
'multi.surbl.org',
'multi.surbl.org',
'dnsrbl.swinog.ch',
'uribl.swinog.ch',
'st.technovision.dk',
'dob.sibl.support-intelligence.net',
'dnsbl.tornevall.org',
'rbl2.triumf.ca',
'truncate.gbudb.net',
'dnsbl-0.uceprotect.net',
'dnsbl-1.uceprotect.net',
'dnsbl-2.uceprotect.net',
'dnsbl-3.uceprotect.net',
'ubl.unsubscore.com',
'black.uribl.com',
'grey.uribl.com',
'multi.uribl.com',
'red.uribl.com',
'dnsbl.inps.de',
'ix.dnsbl.manitu.net',
'b.barracudacentral.org',
'list.bbfh.org',
'dnsbl.sorbs.net',
'bl.blocklist.de',
'bl.spamcop.net',
'zen.spamhaus.org'
}

function file_exists(file) 
        local f=io.open(file,"r")
        if f~=nil then io.close(f) return true else return false end
end


function blacklist_check_short(ips,servers) 

        return blacklist_check_all(ips,servers)
end

function blacklist_check_full(ips,servers) 

        if not file_exists(OUTPUT_FILE_FULL) then
                local handle,err  = io.open(OUTPUT_FILE_FULL,"w")
                for index,ip in ipairs(ips) do
                        handle:write("BLACKLISTCHECK_FULL "..ip.." IN_PROGRESS\n")
                end
                handle:close()
        end
        return blacklist_check_all(ips,servers)
end


-- valid output looks like this:
--
-- <<<postfix_rbl2>>> # the header is written in the check_mk plugin!
--
-- BLACKLISTCHECK_SHORT 93.186.161.43 UNLISTED (checked 8 servers)
-- BLACKLISTCHECK_FULL 93.186.161.43 UNLISTED (checked 213 servers)
-- BLACKLISTCHECK_FULL 93.186.161.43 LISTED bla.dnsbl.org,blubdnsbl.net
-- BLACKLISTCHECK_FULL 93.186.161.43 IN_PROGRESS 

--- main program start

check_short = #arg > 0 and arg[1]:len() > 0 and arg[1]=="-s"
check_full  = #arg > 0 and arg[1]:len() > 0 and arg[1]=="-f"

if (#arg == 0 and not (check_short or check_full) ) then
        print("\nUsage: "..debug.getinfo(1,'S').source:sub(2).." [ -f | -s ]");
        print("\n       -f      Full Scan of all "..#blacklistcheck_servers_all.." servers");
        print(  "       -s      Short Scan of the most important "..#blacklistcheck_servers.." servers\n");
        print("\n	Output directory: "..OUTPUT_DIR.."\n");
        os.exit()
end

-- only check if postfix is installed 

local file 

if(check_command(CMD["POSTCONF"])) then 
        init()
        local listen_ips = get_blacklist_check_ips()
        if(check_short) then
                local res  = blacklist_check_short(listen_ips,blacklistcheck_servers)
                      file = OUTPUT_FILE_SHORT
        else
                local res = blacklist_check_full (listen_ips,blacklistcheck_servers_all)
                      file = OUTPUT_FILE_FULL
        end
        local handle,err  = io.open(file,"w")
        local nr_servers = (check_short and #blacklistcheck_servers) or #blacklistcheck_servers_all
        for ip,arr in pairs(res) do

                handle:write(   "BLACKLISTCHECK_"..((check_short and "SHORT") or "FULL") 
                                .. " " .. ip .. " " 
                                .. ((arr[1] and ("UNLISTED ".. "(checked "..nr_servers.." servers)")) 
                                   or ("LISTED "..arr[2])).."\n")
        end
        handle:close()
else
	print("No postconf, exiting")

end

