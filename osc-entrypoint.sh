#!/bin/bash

if [ ! -f /usercontent/config ]; then
  >&2 echo "Saving environment variables"
  ENCRYPTION_KEY="${ENCRYPTION_KEY:-$(openssl rand -base64 36)}"
  WEBHOOK_SECRET_KEY="${WEBHOOK_SECRET_KEY:-$(openssl rand -base64 36)}"
  APP_SECRET_KEY="${APP_SECRET_KEY:-$(openssl rand -base64 36)}"
  echo "ENCRYPTION_KEY=$ENCRYPTION_KEY" >> /usercontent/config
  echo "WEBHOOK_SECRET_KEY=$WEBHOOK_SECRET_KEY" >> /usercontent/config
  echo "APP_SECRET_KEY=$APP_SECRET_KEY" >> /usercontent/config
fi

# initiate env. vars. from /automatisch/storage/.env file
export $(grep -v '^#' /usercontent/config | xargs)

# migration for webhook secret key, will be removed in the future.
if [[ -z "${WEBHOOK_SECRET_KEY}" ]]; then
  WEBHOOK_SECRET_KEY="$(openssl rand -base64 36)"
  echo "WEBHOOK_SECRET_KEY=$WEBHOOK_SECRET_KEY" >> /usercontent/config
fi

echo "Environment variables have been set!"

if [[ ! -z "$OSC_HOSTNAME" ]]; then
  export HOST="$OSC_HOSTNAME"
else
  export HOST="localhost"
fi

if [[ ! -z "$REDIS_URL" ]]; then
  # Extract host and port from REDIS_URL
  REDIS_HOST=$(echo "$REDIS_URL" | sed 's|redis://||' | sed 's|:[0-9]*$||')
  REDIS_PORT=$(echo "$REDIS_URL" | sed 's|.*:||')
  export REDIS_HOST
  export REDIS_PORT
else
  export REDIS_HOST="localhost"
  export REDIS_PORT="6379"
fi

if [[ ! -z "$POSTGRES_URL" ]]; then
  # Extract components from POSTGRES_URL
  # Format: postgres://username:password@host:port/database
  POSTGRES_USERNAME=$(echo "$POSTGRES_URL" | sed 's|postgres://||' | sed 's|:.*||')
  POSTGRES_PASSWORD=$(echo "$POSTGRES_URL" | sed 's|postgres://[^:]*:||' | sed 's|@.*||')
  POSTGRES_HOST=$(echo "$POSTGRES_URL" | sed 's|postgres://[^@]*@||' | sed 's|:[0-9]*.*||')
  POSTGRES_PORT=$(echo "$POSTGRES_URL" | sed 's|.*:||' | sed 's|/.*||')
  POSTGRES_DATABASE=$(echo "$POSTGRES_URL" | sed 's|.*/||')
  export POSTGRES_USERNAME
  export POSTGRES_PASSWORD
  export POSTGRES_HOST
  export POSTGRES_PORT
  export POSTGRES_DATABASE
else
  export POSTGRES_HOST="localhost"
  export POSTGRES_PORT="5432"
  export POSTGRES_DATABASE="automatisch"
fi

echo "HOST=$HOST"
echo "REDIS_HOST=$REDIS_HOST"
echo "REDIS_PORT=$REDIS_PORT"

echo "POSTGRES_HOST=$POSTGRES_HOST"
echo "POSTGRES_PORT=$POSTGRES_PORT"
echo "POSTGRES_DATABASE=$POSTGRES_DATABASE"
echo "POSTGRES_USERNAME=$POSTGRES_USERNAME"
echo "POSTGRES_PASSWORD=***"

cd packages/backend

yarn db:migrate
yarn db:seed:user

yarn start:worker &
yarn start
