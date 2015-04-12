VERSION = 1.1
PLUGIN = ipv4
all: $(PLUGIN)-$(VERSION).mkp

$(PLUGIN)-$(VERSION).mkp: agents.tar checks.tar info checkman.tar
	tar -czvf $(PLUGIN)-$(VERSION).mkp agents.tar checkman.tar checks.tar info

info: Makefile info.template
	sed -re 's/%VERSION%/$(VERSION)/' info.template >info

agents.tar: plugins/ipv4_addresses
	tar -cf agents.tar plugins/ipv4_addresses

checks.tar: checks/ipv4.addresses
	tar -cf checks.tar -C checks ipv4.addresses

checkman.tar: checkman/ipv4.addresses
	tar -cf checkman.tar -C checkman ipv4.addresses

clean:
	rm -f checks.tar agents.tar checkman.tar info 

all-clean: clean
	rm -f $(PLUGIN)-$(VERSION).mkp 
