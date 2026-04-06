PLATFORM ?= linux

all: check-version
ifeq ($(PLATFORM),macos)
	bash gcc-$(VERSION)-macos.sh
else
	docker build -f gcc-$(VERSION).Dockerfile --target export --output build-gcc-$(VERSION) .
endif

clean:
	rm -rf build-gcc-*/

check-version:
ifndef VERSION
	$(error You must specify a VERSION e.g. `make VERSION=2.8.1`)
endif
ifeq ($(PLATFORM),macos)
ifeq ($(wildcard gcc-$(VERSION)-macos.sh),)
	$(error Building GCC $(VERSION) for macOS is not currently supported)
endif
else
ifeq ($(wildcard gcc-$(VERSION).Dockerfile),)
	$(error Building GCC $(VERSION) is not currently supported)
endif
endif

.PHONY: all check-version
