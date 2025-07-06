# Makefile para POC CDC
# Projeto de Change Data Capture usando MySQL, Debezium (Kafka) e Apache Druid

.PHONY: help build up down restart logs clean api-build api-run api-test mysql kafka druid api all

# Variáveis
COMPOSE_FILES = -f docker-compose.mysql.yml -f docker-compose.kafka.yml -f docker-compose.api.yml -f docker-compose.druid.yml
API_DIR = ./api
DATA_DIR = ./data

# Comando padrão
.DEFAULT_GOAL := help

help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@echo ""
	@echo "=== Gerenciamento de Serviços ==="
	@echo "  all-up        - Inicia todos os serviços"
	@echo "  all-down      - Para todos os serviços"
	@echo "  all-restart   - Reinicia todos os serviços"
	@echo "  all-logs      - Mostra logs de todos os serviços"
	@echo ""
	@echo "=== Serviços Individuais ==="
	@echo "  mysql-up      - Inicia apenas MySQL"
	@echo "  kafka-up      - Inicia Kafka + Zookeeper + Connect"
	@echo "  api-up        - Inicia apenas a API"
	@echo "  druid-up      - Inicia Apache Druid"
	@echo ""
	@echo "=== Desenvolvimento ==="
	@echo "  api-build     - Constrói a imagem da API"
	@echo "  api-run       - Executa a API localmente (sem Docker)"
	@echo "  api-test      - Testa a API"
	@echo "  api-logs      - Mostra logs da API"
	@echo ""
	@echo "=== Limpeza ==="
	@echo "  clean         - Remove containers, networks e volumes"
	@echo "  clean-data    - Remove dados persistentes"
	@echo "  clean-logs    - Remove arquivos de log"
	@echo ""
	@echo "=== Utilitários ==="
	@echo "  status        - Mostra status dos containers"
	@echo "  logs          - Mostra logs de um serviço específico"
	@echo "  shell         - Acessa shell de um container"
	@echo "  test-api      - Testa inserção de cliente via API"

# === Gerenciamento de Serviços ===

all-up: ## Inicia todos os serviços
	docker compose $(COMPOSE_FILES) up -d

all-down: ## Para todos os serviços
	docker compose $(COMPOSE_FILES) down

all-restart: ## Reinicia todos os serviços
	docker compose $(COMPOSE_FILES) restart

all-logs: ## Mostra logs de todos os serviços
	docker compose $(COMPOSE_FILES) logs -f

# === Serviços Individuais ===

mysql-up: ## Inicia apenas MySQL
	docker compose -f docker-compose.mysql.yml up -d

kafka-up: ## Inicia Kafka + Zookeeper + Connect
	docker compose -f docker-compose.kafka.yml up -d

api-up: ## Inicia apenas a API
	docker compose -f docker-compose.api.yml up -d

druid-up: ## Inicia Apache Druid
	docker compose -f docker-compose.druid.yml up -d

# === Desenvolvimento ===

api-build: ## Constrói a imagem da API
	docker compose -f docker-compose.api.yml build

api-run: ## Executa a API localmente (sem Docker)
	cd $(API_DIR) && go run main.go

api-test: ## Testa a API
	@echo "Testando API..."
	@curl -X POST http://localhost:8080/clientes \
		-H 'Content-Type: application/json' \
		-d '{"id":1,"nome":"Teste","email":"teste@example.com"}' || echo "API não está rodando"

api-logs: ## Mostra logs da API
	docker compose -f docker-compose.api.yml logs -f api

# === Limpeza ===

clean: ## Remove containers, networks e volumes
	docker compose $(COMPOSE_FILES) down -v --remove-orphans
	docker system prune -f

clean-data: ## Remove dados persistentes
	@echo "Removendo dados persistentes..."
	@rm -rf $(DATA_DIR)/*
	@echo "Dados removidos!"

clean-logs: ## Remove arquivos de log
	@echo "Removendo arquivos de log..."
	@rm -f *.log
	@echo "Logs removidos!"

# === Utilitários ===

status: ## Mostra status dos containers
	@echo "=== Status dos Containers ==="
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs: ## Mostra logs de um serviço específico (uso: make logs SERVICE=nome_do_servico)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Uso: make logs SERVICE=nome_do_servico"; \
		echo "Serviços disponíveis: mysql, kafka, zookeeper, connect, api, coordinator, broker, historical, middlemanager, router"; \
	else \
		docker logs -f $(SERVICE); \
	fi

shell: ## Acessa shell de um container (uso: make shell SERVICE=nome_do_servico)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Uso: make shell SERVICE=nome_do_servico"; \
		echo "Serviços disponíveis: mysql, kafka, zookeeper, connect, api, coordinator, broker, historical, middlemanager, router"; \
	else \
		docker exec -it $(SERVICE) /bin/bash; \
	fi

test-api: ## Testa inserção de cliente via API
	@echo "Testando inserção de cliente..."
	@curl -X POST http://localhost:8080/clientes \
		-H 'Content-Type: application/json' \
		-d '{"id":1,"nome":"Alice","email":"alice@example.com"}'
	@echo ""
	@echo "Teste concluído!"

# === Comandos de Desenvolvimento Go ===

go-mod: ## Inicializa módulo Go
	cd $(API_DIR) && go mod init poc-cdc-api

go-tidy: ## Organiza dependências Go
	cd $(API_DIR) && go mod tidy

go-test: ## Executa testes Go
	cd $(API_DIR) && go test ./...

go-build: ## Compila a aplicação Go
	cd $(API_DIR) && go build -o bin/api main.go

# === Comandos de Debug ===

debug-cdc: ## Executa script de debug CDC
	@if [ -f "debug-cdc.sh" ]; then \
		chmod +x debug-cdc.sh && ./debug-cdc.sh; \
	else \
		echo "Arquivo debug-cdc.sh não encontrado"; \
	fi

# === Comandos de Monitoramento ===

monitor-kafka: ## Monitora tópicos Kafka
	@echo "Listando tópicos Kafka..."
	@docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

monitor-connect: ## Monitora conectores Kafka Connect
	@echo "Listando conectores..."
	@curl -s http://localhost:8084/connectors | jq .

monitor-druid: ## Verifica status do Druid
	@echo "Verificando status do Druid..."
	@curl -s http://localhost:8888/status | jq .

# === Comandos de Setup ===

setup: ## Configura o ambiente inicial
	@echo "Configurando ambiente..."
	@mkdir -p $(DATA_DIR)
	@echo "Ambiente configurado!"

init-db: ## Inicializa o banco de dados
	@echo "Inicializando banco de dados..."
	@docker exec mysql mysql -uroot -psecret -e "CREATE DATABASE IF NOT EXISTS cdc;"
	@echo "Banco de dados inicializado!"

# === Comandos de Backup ===

backup: ## Faz backup dos dados
	@echo "Fazendo backup dos dados..."
	@tar -czf backup-$(shell date +%Y%m%d-%H%M%S).tar.gz $(DATA_DIR)
	@echo "Backup criado!"

restore: ## Restaura backup (uso: make restore BACKUP=arquivo.tar.gz)
	@if [ -z "$(BACKUP)" ]; then \
		echo "Uso: make restore BACKUP=arquivo.tar.gz"; \
	else \
		echo "Restaurando backup $(BACKUP)..."; \
		tar -xzf $(BACKUP); \
		echo "Backup restaurado!"; \
	fi 