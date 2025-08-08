# Set and create APPDATA folder
export APPDATA=$HOME/dockerAppdata/big-bear-n8n
mkdir -p "$APPDATA/.n8n" "$APPDATA/pgdata" "$APPDATA/db"

# OPTIONAL: Create empty init script if it doesn't exist
touch "$APPDATA/db/init-data.sh"
chmod +x "$APPDATA/db/init-data.sh"

# Create the pod and expose port 5678
podman pod exists big-bear-n8n-pod || podman pod create --name big-bear-n8n-pod -p 5678:5678

# PostgreSQL container
podman run -d \
  --pod big-bear-n8n-pod \
  --name db-n8n \
  --hostname db-n8n \
  --restart=unless-stopped \
  -e POSTGRES_USER=bigbearcasaos \
  -e POSTGRES_PASSWORD=bigbearcasaos \
  -e POSTGRES_DB=n8n \
  --health-cmd='pg_isready -U bigbearcasaos -d n8n' \
  --health-interval=5s \
  --health-timeout=5s \
  --health-retries=10 \
  -v "$APPDATA/pgdata":/var/lib/postgresql/data \
  -v "$APPDATA/db/init-data.sh":/docker-entrypoint-initdb.d/init-data.sh \
  postgres:14.2

# n8n container
podman run -d \
  --pod big-bear-n8n-pod \
  --name n8n \
  --hostname n8n \
  --restart=unless-stopped \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=db-n8n \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n \
  -e DB_POSTGRESDB_USER=bigbearcasaos \
  -e DB_POSTGRESDB_PASSWORD=bigbearcasaos \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=secret \
  -e N8N_HOST=0.0.0.0 \
  -e N8N_PORT=5678 \
  -e N8N_PROTOCOL=http \
  -e WEBHOOK_TUNNEL_URL=http://localhost:5678 \
  -v "$APPDATA/.n8n":/home/node/.n8n \
  -v /:/mnt/root:ro \
  n8nio/n8n
