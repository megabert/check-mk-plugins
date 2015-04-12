SUBDIR_MAKES=$(wildcard */Makefile)
all: $(SUBDIR_MAKES)
.PHONY: force
$(SUBDIR_MAKES): force
	@echo "***** $(dir $@) *****"
	cd $(dir $@) && make all clean
