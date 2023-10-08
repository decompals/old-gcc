ifndef VERSION
$(error You must specify a VERSION e.g. VERSION=2.8.1)
endif

ifeq ($(wildcard gcc-$(VERSION).Dockerfile),)
$(error GCC $(VERSION) is not currently supported)
endif

all:
	docker build -f gcc-$(VERSION).Dockerfile --target export --output build-gcc-$(VERSION) .

clean:
	rm -rf build-gcc-*/

check-version:
ifndef VERSION
	$(error You must specify a VERSION e.g. VERSION=2.8.1)
endif

.PHONY: all check-version
