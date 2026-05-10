.PHONY: help setup run stop restart update delete logs status backup clean

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(BLUE)=== Hermes Agent - Available Commands ===$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Lifecycle:$(NC)"
	@echo "  $(BLUE)make setup$(NC)      - Initialize the Hermes Agent service (run once before first 'make run')"
	@echo "  $(BLUE)make run$(NC)        - Start the service in the background"
	@echo "  $(BLUE)make stop$(NC)       - Stop the running service gracefully"
	@echo "  $(BLUE)make restart$(NC)    - Restart the service (stop → start)"
	@echo "  $(BLUE)make update$(NC)     - Pull latest image and recreate container"
	@echo "  $(BLUE)make delete$(NC)     - Remove containers, volumes, and all data (prompts for confirmation)"
	@echo ""
	@echo "$(GREEN)Monitoring & Inspection:$(NC)"
	@echo "  $(BLUE)make logs$(NC)       - View live logs from the service (Ctrl+C to exit)"
	@echo "  $(BLUE)make status$(NC)     - Display the current status of the service"
	@echo ""
	@echo "$(GREEN)Data Management:$(NC)"
	@echo "  $(BLUE)make backup$(NC)     - Backup the hermes-data volume to ./backups/"
	@echo ""
	@echo "$(GREEN)Utility:$(NC)"
	@echo "  $(BLUE)make help$(NC)       - Show this help message"
	@echo "  $(BLUE)make clean$(NC)      - Remove backup directory (does not affect service data)"
	@echo ""

# Load environment variables from .env if it exists
-include .env

# Default values if .env doesn't exist
SERVICE_NAME ?= hermes
CONTAINER_NAME ?= hermes
IMAGE ?= nousresearch/hermes-agent
DATA_VOLUME ?= hermes-data
RESTART_POLICY ?= unless-stopped

# Backup directory
BACKUP_DIR := backups
BACKUP_TIMESTAMP := $(shell date +%Y-%m-%d-%H-%M-%S)
BACKUP_FILE := $(BACKUP_DIR)/$(DATA_VOLUME)-$(BACKUP_TIMESTAMP).tar.gz

setup:
	@echo "$(BLUE)Setting up Hermes Agent...$(NC)"
	@echo "Running initialization (this may take a moment)..."
	@docker compose run -it --rm --no-deps $(SERVICE_NAME) setup
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo "Next step: run $(BLUE)make run$(NC) to start the service"

run:
	@echo "$(BLUE)Starting Hermes Agent service...$(NC)"
	@docker compose up -d
	@echo "$(GREEN)✓ Service started in background$(NC)"
	@echo "Check status: $(BLUE)make status$(NC)"
	@echo "View logs:   $(BLUE)make logs$(NC)"

stop:
	@echo "$(YELLOW)Stopping Hermes Agent service...$(NC)"
	@docker compose stop
	@echo "$(GREEN)✓ Service stopped$(NC)"
	@echo "Note: Data in volumes is preserved"
	@echo "To start again: $(BLUE)make run$(NC)"

restart:
	@echo "$(YELLOW)Restarting Hermes Agent service...$(NC)"
	@docker compose restart
	@echo "$(GREEN)✓ Service restarted$(NC)"
	@echo "View logs: $(BLUE)make logs$(NC)"

update:
	@echo "$(BLUE)Updating Hermes Agent image...$(NC)"
	@docker compose pull
	@docker compose up -d
	@echo "$(GREEN)✓ Update complete$(NC)"
	@echo "Current status: $(BLUE)make status$(NC)"

logs:
	@echo "$(BLUE)Displaying live logs (Ctrl+C to exit)...$(NC)"
	@docker compose logs -f

status:
	@echo "$(BLUE)=== Hermes Agent Status ===$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(BLUE)Volume Status:$(NC)"
	@docker volume ls | grep $(DATA_VOLUME) || echo "No volume found"
	@echo ""

delete:
	@echo "$(RED)WARNING: This will delete ALL Hermes Agent containers, volumes, and data!$(NC)"
	@echo "Data in the $(DATA_VOLUME) volume will be PERMANENTLY DELETED."
	@echo ""
	@read -p "Are you absolutely sure you want to continue? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(RED)Deleting Hermes Agent...$(NC)"; \
		docker compose down -v; \
		echo "$(GREEN)✓ Deleted: containers, networks, and volumes$(NC)"; \
		echo ""; \
		echo "To restore from backup:"; \
		echo "  1. make setup"; \
		echo "  2. make run"; \
		echo "  3. Manually restore data (see README for instructions)"; \
	else \
		echo "$(YELLOW)Deletion cancelled.$(NC)"; \
	fi

backup:
	@echo "$(BLUE)Creating backup of $(DATA_VOLUME)...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@echo "Backup file: $(BACKUP_FILE)"
	@echo "This may take a moment depending on data size..."
	@docker run --rm -v $(DATA_VOLUME):/data -v $$(pwd)/$(BACKUP_DIR):/backup alpine tar czf /backup/$(DATA_VOLUME)-$(BACKUP_TIMESTAMP).tar.gz -C /data .
	@echo "$(GREEN)✓ Backup complete!$(NC)"
	@echo "Location: $(BACKUP_FILE)"
	@ls -lh $(BACKUP_FILE)

clean:
	@echo "$(YELLOW)Removing backup directory...$(NC)"
	@rm -rf $(BACKUP_DIR)
	@echo "$(GREEN)✓ Backup directory removed$(NC)"
	@echo "Note: This does NOT affect service data or volumes"

.DEFAULT_GOAL := help
