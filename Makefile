all:
	clear
	docker-compose up --build -d

down:
	docker-compose down

stop:
	docker-compose stop

start:
	docker-compose start

clean:
	@docker stop $$(docker ps -qa) || true
	@docker rm -f $$(docker ps -qa) || true
	@docker rmi -f $$(docker images -qa) || true
	@docker volume rm -f $$(docker volume ls -q) || true
	@docker network rm $$(docker network ls -q) || true

prune: clean
	@docker system prune -a --volumes -f

re: clean all

oci:
	@docker-compose exec -it oci zsh

.PHONY: all up down stop start clean re prune