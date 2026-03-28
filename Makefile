docker_exec = docker compose exec --user nobody app

help:
	cat Makefile
install:
	docker compose down -v --remove-orphans
	docker compose up -d
	${docker_exec} composer install
	cp ./.env.example ./.env
	${docker_exec} php artisan key:generate
	${docker_exec} php artisan config:clear
	${docker_exec} php artisan cache:clear
up:
	docker compose up -d
rebuild:
	docker compose up -d --build
down:
	docker compose down
sh:
	${docker_exec} sh
route:
	${docker_exec} php artisan route:list --except-vendor
clear:
	${docker_exec} php artisan clear-compiled
	${docker_exec} php artisan cache:clear
	${docker_exec} php artisan config:clear
