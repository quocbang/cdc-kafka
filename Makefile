cdc-infrastructure:
	docker-compose -f ./infrastructures/docker-compose.yml --env-file ./.env down && docker compose -f ./infrastructures/docker-compose.yml --env-file ./.env up --build -d;