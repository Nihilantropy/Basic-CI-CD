# Docker compose command definition
DOCKER_COMPOSE = docker compose
COMPOSE_FOLDER = ./srcs
COMPOSE_FILE = $(COMPOSE_FOLDER)/docker-compose.yaml
FOLDER_PREFIX = srcs_
REPO_PREFIX = my_
TAG = 0.1.0

# List of CI/CD service names to identify related images
PROJECT_SERVICES = gitlab \
                   jenkins-docker \
                   jenkins \
                   nexus \
				   prometheus \
				   pushgateway \
				   alertmanager \
				   grafana

# List of CI/CD volumes and networks as defined in docker-compose.yml
PROJECT_VOLUMES = gitlab_data \
                   gitlab_logs \
                   gitlab_config \
                   jenkins_home \
				   jenkins-docker-certs \
                   nexus_data \
				   prometheus_data \
				   alertmanager_data \
				   grafana_data

PROJECT_NETWORKS = $(FOLDER_PREFIX)gitlab_network

all: setup images up show

setup:
	@echo "Setup step is no longer needed as volumes are managed by Docker."

images:
	@echo "Building images..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) build --parallel
	@echo "Images build done!"

up:
	@echo "Starting containers..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up -d
	@echo "Containers started!"

show:
	@echo ============= Containers =============
	@docker ps -a
	@echo
	@echo ============= Networks =============
	@docker network ls --filter name="$(FOLDER_PREFIX)"
	@echo
	@echo ============= Volumes =============
	@docker volume ls
	@echo

stop:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) stop

start:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) start

down:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down

restart:
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) restart

re: prune all

prune:
	@echo "Deleting all CI/CD-related resources..."
	@echo "Stopping containers..."
	@$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down -v 2>/dev/null || true
	@echo "Removing CI/CD images..."
	@for service in $(PROJECT_SERVICES); do \
		docker rmi -f $(REPO_PREFIX)$$service:$(TAG) 2>/dev/null || true; \
	done
	@echo "Removing CI/CD volumes..."
	@for volume in $(PROJECT_VOLUMES); do \
		docker volume rm $$volume 2>/dev/null || true; \
	done
	@echo "Removing CI/CD networks..."
	@for network in $(PROJECT_NETWORKS); do \
		docker network rm $$network 2>/dev/null || true; \
	done
	@echo "Done! All CI/CD-related resources have been removed."

.PHONY: all setup images start show stop up down restart re prune
