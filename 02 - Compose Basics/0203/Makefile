.PHONY: up down start stop cleanContainers clean

up:
	docker-compose up $(opts)

down:
	docker-compose down $(opts)

start:
	docker-compose up -d $(opts)

cleanContainers:
	docker-compose rm --force --all

cleanVolumes:
	rm -rf volumes

clean: cleanContainers cleanVolumes


