VERSION = 1.0
PLUGIN = postfix_processed
all: $(PLUGIN)-$(VERSION).mkp

$(PLUGIN)-$(VERSION).mkp: agents.tar checks.tar info checkman.tar
	tar -czvf $(PLUGIN)-$(VERSION).mkp agents.tar checkman.tar checks.tar info

info: Makefile info.template
	sed -re 's/%VERSION%/$(VERSION)/' info.template >info

agents.tar: plugins/postfix_processed
	tar -cf agents.tar plugins/postfix_processed

checks.tar: checks/postfix_processed
	tar -cf checks.tar -C checks postfix_processed

checkman.tar: checkman/postfix_processed
	tar -cf checkman.tar -C checkman postfix_processed

clean:
	rm -f checks.tar agents.tar checkman.tar info 

all-clean: clean
	rm -f $(PLUGIN)-$(VERSION).mkp 
