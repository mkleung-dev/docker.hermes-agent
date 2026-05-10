# Hermes Agent

A Docker-based deployment of the **Nous Research Hermes Agent** — an AI agent service that runs as a gateway server for processing requests with persistent data storage.

## Quick Start

### Prerequisites
- Docker & Docker Compose installed ([Installation Guide](https://docs.docker.com/get-started/get-docker/))
- `make` utility (usually pre-installed on Linux/macOS, or use WSL2 on Windows)

### 3-Step Setup

```bash
# 1. Initialize the service (one-time setup)
make setup

# 2. Start the service in the background
make run

# 3. Verify it's running and view logs
make logs
```

That's it! The Hermes Agent is now running. Press `Ctrl+C` to exit the logs viewer.

## Detailed Usage Guide

All operations are managed through the **Makefile**. Run `make help` to see all available commands:

```bash
make help
```

### Available Commands

#### Setup & Lifecycle Management

| Command | Description |
|---------|-------------|
| `make setup` | Initialize the Hermes Agent service (run once before first `make run`) |
| `make run` | Start the service in the background (detached mode) |
| `make stop` | Stop the running service gracefully |
| `make restart` | Restart the service (stop → start) |
| `make update` | Pull the latest image and recreate the running container |
| `make delete` | **Remove everything:** containers, volumes, and all data (prompts for confirmation) |

#### Monitoring & Inspection

| Command | Description |
|---------|-------------|
| `make logs` | View live logs from the Hermes Agent service (press `Ctrl+C` to exit) |
| `make status` | Display the current status of the service container |

#### Data Management

| Command | Description |
|---------|-------------|
| `make backup` | Backup the `hermes-data` volume to a timestamped tar file in `./backups/` |
| `make help` | Display this help message |

### Usage Examples

```bash
# Start the service and check if it's running
make run
make status

# Monitor logs in real-time
make logs

# Create a backup before making changes
make backup
# Backup file: ./backups/hermes-data-2026-05-09-14-30-45.tar.gz

# Temporarily stop the service without deleting data
make stop

# Restart the service
make restart

# Pull latest image and update running container
make update

# Completely remove the service and its data
make delete  # Requires confirmation
```

## Configuration

The service can be customized via environment variables. Configuration is managed through the `.env` file.

### Creating Your Configuration

```bash
# Copy the example configuration to create your own
cp .env.example .env

# Edit .env to customize (optional - defaults work for most use cases)
nano .env
```

### Available Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVICE_NAME` | `hermes` | Service name in docker-compose |
| `CONTAINER_NAME` | `hermes` | Name of the running Docker container |
| `IMAGE` | `nousresearch/hermes-agent` | Docker image to use |
| `DATA_VOLUME` | `hermes-data` | Name of the Docker volume for persistent data |
| `RESTART_POLICY` | `unless-stopped` | Container restart behavior (`no`, `always`, `unless-stopped`, `on-failure`) |

## Data Persistence

The Hermes Agent stores all persistent data in the Docker volume `hermes-data`, which is mounted at `/opt/data` inside the container.

### Data Safety

- **Persistent Across Restarts:** Data survives container restarts and reboots
- **Volume-Based Storage:** Data is stored outside the container filesystem
- **Backup Recommendations:** Before major changes, create a backup:
  ```bash
  make backup
  ```

### Backup & Restore

**Create a backup:**
```bash
make backup
# Creates: ./backups/hermes-data-2026-05-09-14-30-45.tar.gz
```

**Restore from backup (manual process):**
```bash
# Stop the service first
make stop

# Extract the backup to a temporary location
tar -xzf ./backups/hermes-data-YYYY-MM-DD-HH-MM-SS.tar.gz -C /tmp/

# Remove the current volume data and restore
docker volume rm hermes-data
docker volume create hermes-data

# Copy data back (requires running container)
make run
docker compose cp /tmp/hermes-data/. hermes:/opt/data

# Restart to apply changes
make restart
```

## Troubleshooting

### Service won't start: "Container exiting immediately"

**Check the logs:**
```bash
make logs
```

**Common causes:**
- Initial setup not completed — run `make setup`
- Corrupted volume data — create backup, then `make delete && make setup && make run`
- Port conflicts — check if another service is using the same ports

### Container crashes after restart

**Inspect the issue:**
```bash
make status
make logs
```

**Try restarting:**
```bash
make restart
```

If it continues to fail, check the Hermes Agent logs for specific error messages.

### High disk usage or slow performance

**Backup and clean:**
```bash
make backup
make delete
make setup
make run
```

### Access denied errors or permission issues

**Verify Docker permissions:**
```bash
docker ps  # Should work without sudo
```

If this fails, add your user to the Docker group:
```bash
sudo usermod -aG docker $USER
# Restart your terminal session for changes to take effect
```

## Architecture

```
Hermes Agent Service
├── Docker Container (hermes)
├── Command: gateway run
├── Image: nousresearch/hermes-agent
└── Volume: hermes-data (/opt/data)
    └── Persistent data storage
```

**How it works:**
1. The container runs the `gateway run` command at startup
2. The gateway server listens for incoming requests
3. All data is stored in the `hermes-data` volume at `/opt/data`
4. The service auto-restarts if it crashes (unless stopped manually)

## Environment Details

- **Service Name:** `hermes`
- **Container Name:** `hermes`
- **Image:** `nousresearch/hermes-agent:latest`
- **Data Mount:** `/opt/data` (container path)
- **Volume:** `hermes-data` (Docker named volume)
- **Restart Policy:** `unless-stopped` (auto-restart on failure, unless manually stopped)
- **Execution Mode:** Detached/background service

## Project Structure

```
hermes-agent/
├── Makefile              # Build automation & command entry point
├── docker-compose.yaml   # Service definition (uses .env variables)
├── .env.example          # Configuration template
├── README.md             # This file
└── backups/              # Backup directory (auto-created on first backup)
    └── hermes-data-YYYY-MM-DD-HH-MM-SS.tar.gz
```

## Useful Links

- [Nous Research Hermes](https://huggingface.co/NousResearch) — Official Hermes models and documentation
- [Docker Compose Documentation](https://docs.docker.com/compose/) — Docker Compose reference
- [Docker Volumes](https://docs.docker.com/storage/volumes/) — Understanding Docker volumes
- [Makefile Tutorial](https://www.gnu.org/software/make/manual/) — GNU Make reference

## Common Tasks

### Monitor service health
```bash
watch make status  # Refresh status every 2 seconds
```

### Completely reset the service
```bash
make backup      # Always backup first!
make delete      # Remove containers and volumes
make setup       # Re-initialize
make run         # Start fresh
```

### Schedule regular backups (using cron)
```bash
# Add to crontab (run daily at 2 AM)
0 2 * * * cd /home/mkleung/docker-related/hermes-agent && make backup >> /var/log/hermes-backup.log 2>&1
```

## Getting Help

1. **Check logs:** `make logs`
2. **Check status:** `make status`
3. **Review this README:** Section on Troubleshooting
4. **Docker documentation:** [docs.docker.com](https://docs.docker.com)
5. **Nous Research:** [huggingface.co/NousResearch](https://huggingface.co/NousResearch)

## License & Attribution

This deployment configuration is provided as-is. The Hermes Agent image is maintained by [Nous Research](https://www.nousresearch.com/). Refer to their documentation and license for the actual Hermes Agent service.

---

**Last Updated:** May 2026  
**Version:** 1.0
