all:
	docker-compose up -d --build

clean:
	rm -rf build/

.PHONY: all