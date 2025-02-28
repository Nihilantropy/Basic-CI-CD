# Docker compose command definition
DOCKER_COMPOSE = docker compose
COMPOSE_FOLDER = ./srcs
COMPOSE_FILE = $(COMPOSE_FOLDER)/docker-compose.yaml
DATA_PATH = $(HOME)/data
FOLDER_PREFIX = srcs_

# List of CI/CD service names to identify related images
PROJECT_SERVICES = gitlab \
                   jenkins \
                   nexus

# List of CI/CD volumes and networks
PROJECT_VOLUMES = $(FOLDER_PREFIX)gitlab_data \
                   $(FOLDER_PREFIX)gitlab_logs \
                   $(FOLDER_PREFIX)gitlab_config \
                   $(FOLDER_PREFIX)jenkins_home \
                   $(FOLDER_PREFIX)nexus_data
PROJECT_NETWORKS = $(FOLDER_PREFIX)gitlab_network

all: setup images up show

setup: setup_volumes

setup_volumes:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/gitlab
	@mkdir -p $(DATA_PATH)/jenkins
	@mkdir -p $(DATA_PATH)/nexus
	@echo "Data directories created!"

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
	@docker volume ls --filter name=$(FOLDER_PREFIX)
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
	@echo "Removing CI/CD containers..."
	@for service in $(PROJECT_SERVICES); do \
		docker rm -f $$service 2>/dev/null || true; \
	done
	@echo "Removing CI/CD images..."
	@for service in $(PROJECT_SERVICES); do \
		docker rmi -f $$service 2>/dev/null || true; \
	done
	@echo "Removing CI/CD volumes..."
	@for volume in $(PROJECT_VOLUMES); do \
		docker volume rm $$volume 2>/dev/null || true; \
	done
	@echo "Removing CI/CD networks..."
	@for network in $(PROJECT_NETWORKS); do \
		docker network rm $$network 2>/dev/null || true; \
	done
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)/* 2>/dev/null || true
	@echo "Done! All CI/CD-related resources have been removed."

.PHONY: all setup setup_volumes images start show stop up down restart re prune
