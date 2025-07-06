#!/bin/bash

OUT=cdc-debug.log
echo "[CDC DEBUG LOG - $(date)]" > "$OUT"

echo -e "\n--- MySQL: SHOW MASTER STATUS ---" >> "$OUT"
docker exec mysql mysql -uroot -psecret -e "SHOW MASTER STATUS\G" >> "$OUT" 2>&1

echo -e "\n--- MySQL: SHOW GRANTS ---" >> "$OUT"
docker exec mysql mysql -uroot -psecret -e "SHOW GRANTS FOR 'root'@'%';" >> "$OUT" 2>&1

echo -e "\n--- MySQL: SHOW VARIABLES LIKE '%binlog%' ---" >> "$OUT"
docker exec mysql mysql -uroot -psecret -e "SHOW VARIABLES LIKE '%binlog%';" >> "$OUT" 2>&1

echo -e "\n--- Kafka: List Topics ---" >> "$OUT"
docker exec kafka kafka-topics --bootstrap-server kafka:9092 --list >> "$OUT" 2>&1

echo -e "\n--- Kafka: Consume Topic (5s) ---" >> "$OUT"
docker exec kafka kafka-console-consumer --bootstrap-server kafka:9092 \
  --topic cdc-server.cdc.clientes --from-beginning --timeout-ms 5000 >> "$OUT" 2>&1

echo -e "\n--- Kafka Connect: Connector Status ---" >> "$OUT"
curl -s http://localhost:8084/connectors/mysql-clientes-connector/status >> "$OUT"

echo -e "\n--- Kafka Connect: Connector Config ---" >> "$OUT"
curl -s http://localhost:8084/connectors/mysql-clientes-connector >> "$OUT"

echo -e "\n--- Kafka Connect: Container Logs (últimos 1000) ---" >> "$OUT"
docker logs --tail=1000 kafka-connect >> "$OUT" 2>&1

echo -e "\n--- Druid: Supervisor List ---" >> "$OUT"
curl -s http://localhost:8888/druid/indexer/v1/supervisor >> "$OUT"

echo -e "\n--- Druid: Supervisor Status ---" >> "$OUT"
curl -s http://localhost:8888/druid/indexer/v1/supervisor/clientes/status >> "$OUT"

echo -e "\n--- Fim do log ---" >> "$OUT"

echo "[✓] Log gerado: $OUT"