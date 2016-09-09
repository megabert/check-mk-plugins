SUBDIR_MAKES=$(wildcard */Makefile)
  CLEAN_DIRS=$(addprefix clean_,$(SUBDIR_MAKES))
all: $(SUBDIR_MAKES)
.PHONY: force
$(SUBDIR_MAKES): force
	@echo "***** $(dir $@) *****"
	cd $(dir $@) && make all clean

clean: $(CLEAN_DIRS)
$(CLEAN_DIRS): force
	cd $(patsubst clean_%,%,$(dir $@)) && make all-clean

