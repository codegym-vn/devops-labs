#!/bin/bash

# Khoi dong PostgreSQL 15 tren port 5432
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=postgres_secret \
  -e POSTGRES_DB=ecommerce_db \
  -p 5432:5432 \
  --restart=always \
  postgres:15-alpine > /dev/null 2>&1

# Khoi dong Redis 7 tren port 6379
docker run -d --name redis \
  -p 6379:6379 \
  --restart=always \
  redis:7-alpine > /dev/null 2>&1

# Tao CLI wrapper cho psql
cat << 'EOF' > /usr/local/bin/psql
#!/bin/bash
if [ $# -eq 0 ]; then
  docker exec -it postgres psql -U postgres -d ecommerce_db
elif [ -t 0 ]; then
  docker exec -it postgres psql "$@"
else
  docker exec -i postgres psql "$@"
fi
EOF
chmod +x /usr/local/bin/psql

# Tao CLI wrapper cho redis-cli
cat << 'EOF' > /usr/local/bin/redis-cli
#!/bin/bash
if [ -t 0 ]; then
  docker exec -it redis redis-cli "$@"
else
  docker exec -i redis redis-cli "$@"
fi
EOF
chmod +x /usr/local/bin/redis-cli

# Tao CLI wrapper cho flyway
cat << 'EOF' > /usr/local/bin/flyway
#!/bin/bash
docker run --rm --net=host \
  -v /root/migrations:/flyway/sql \
  -v /root/flyway.conf:/flyway/conf/flyway.conf \
  flyway/flyway:9 "$@"
EOF
chmod +x /usr/local/bin/flyway

# Chuan bi thu muc ung dung va migrations
mkdir -p /root/app /root/migrations

# File mau cau hinh bien moi truong
cat << 'EOF' > /root/app/.env.example
# Database Connection & Pooling
DATABASE_URL=postgresql://store_admin:admin_secret_999@localhost:5432/ecommerce_db
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_TIMEOUT=30

# Redis Cache Configuration
REDIS_URL=redis://localhost:6379/0
CACHE_TTL=60
EOF

# File cau hinh Flyway mac dinh
cat << 'EOF' > /root/flyway.conf
flyway.url=jdbc:postgresql://localhost:5432/ecommerce_db
flyway.user=postgres
flyway.password=postgres_secret
flyway.locations=filesystem:/flyway/sql
flyway.baselineOnMigrate=true
EOF

# Tai truoc flyway image trong nen
docker pull flyway/flyway:9 > /dev/null 2>&1 &

# Cho PostgreSQL khoi dong xong socket
for i in $(seq 1 15); do
  if docker exec postgres pg_isready -U postgres > /dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Danh dau moi truong da san sang
touch /tmp/.lab_ready
