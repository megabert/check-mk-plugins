VERSION = 1.0
PLUGIN = confixx
all: $(PLUGIN)-$(VERSION).mkp

$(PLUGIN)-$(VERSION).mkp: agents.tar checks.tar info checkman.tar
	tar -czvf $(PLUGIN)-$(VERSION).mkp agents.tar checkman.tar checks.tar info

info: Makefile info.template
	sed -re 's/%VERSION%/$(VERSION)/' info.template >info

agents.tar: plugins/confixx
	tar -cf agents.tar plugins/confixx

checks.tar: checks/confixx.license
	tar -cf checks.tar -C checks confixx.license

checkman.tar: checkman/confixx.license
	tar -cf checkman.tar -C checkman confixx.license

clean:
	rm -f checks.tar agents.tar checkman.tar info 

all-clean: clean
	rm -f $(PLUGIN)-$(VERSION).mkp 
