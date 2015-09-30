VERSION = 1.0
PLUGIN = postfix_rbl
all: $(PLUGIN)-$(VERSION).mkp

$(PLUGIN)-$(VERSION).mkp: agents.tar checks.tar info checkman.tar
	tar -czvf $(PLUGIN)-$(VERSION).mkp agents.tar checkman.tar checks.tar info

info: Makefile info.template
	sed -re 's/%VERSION%/$(VERSION)/' info.template >info

agents.tar: plugins/postfix.rbl
	tar -cf agents.tar plugins/postfix.rbl

checks.tar: checks/postfix.rbl
	tar -cf checks.tar -C checks postfix.rbl

checkman.tar: checkman/postfix.rbl
	tar -cf checkman.tar -C checkman postfix.rbl

clean:
	rm -f checks.tar agents.tar checkman.tar info 

all-clean: clean
	rm -f $(PLUGIN)-$(VERSION).mkp 
