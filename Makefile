ifndef VERSION
$(error You must specify a VERSION e.g. VERSION=2.8.1)
endif

all:
	mkdir -p build-gcc-$(VERSION)
	docker compose up --build && docker compose down

clean:
	rm -rf build-gcc-*/

.PHONY: all
