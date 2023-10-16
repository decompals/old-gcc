all: check-version
	docker build -f gcc-$(VERSION).Dockerfile --target export --output build-gcc-$(VERSION) .

clean:
	rm -rf build-gcc-*/

check-version:
ifndef VERSION
	$(error You must specify a VERSION e.g. `make VERSION=2.8.1`)
endif
ifeq ($(wildcard gcc-$(VERSION).Dockerfile),)
	$(error Building GCC $(VERSION) is not currently supported)
endif

.PHONY: all check-version
