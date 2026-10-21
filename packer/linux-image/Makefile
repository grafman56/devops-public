PACKER  ?= packer
VARS    ?= -var-file=build.pkrvars.hcl

.PHONY: init fmt validate build clean

init:
	$(PACKER) init .

fmt:
	$(PACKER) fmt -recursive .

validate: init
	$(PACKER) validate $(VARS) .

build: init
	$(PACKER) build -timestamp-ui $(VARS) . 2>&1 | tee build/packer.log

clean:
	rm -rf build packer_cache
