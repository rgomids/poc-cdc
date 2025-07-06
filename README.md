# PoC CDC

This repository contains a proof of concept for Change Data Capture (CDC) using MySQL, Debezium (Kafka), and Apache Druid. The services are split across multiple `docker-compose` files so that you can start them individually or together.

## Compose files

- `docker-compose.mysql.yml` – MySQL with binlog enabled
- `docker-compose.kafka.yml` – Zookeeper, Kafka and Kafka Connect with the Debezium plugin
- `docker-compose.api.yml` – Simple Go API exposing `POST /clientes` that writes to MySQL
- `docker-compose.druid.yml` – Apache Druid services using the provided `environment` file

All compose files share the same network `cdc-net` and use bind mounted volumes under the `./data` directory so data is persisted locally.

## Running

You can bring everything up with Docker Compose:

```bash
docker compose \
  -f docker-compose.mysql.yml \
  -f docker-compose.kafka.yml \
  -f docker-compose.api.yml \
  -f docker-compose.druid.yml up -d
```

The API will be available on `http://localhost:8080` and Druid's Router on `http://localhost:8888`.

## API example

Insert a new client:

```bash
curl -X POST http://localhost:8080/clientes \
  -H 'Content-Type: application/json' \
  -d '{"id":1,"nome":"Alice","email":"alice@example.com"}'
```

The insert is written to MySQL, captured by Debezium via Kafka and ingested in real time by Druid.
