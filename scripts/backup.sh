#!/bin/bash

# Script de Backup Automático - LiaLean Server
# Versão: 1.0
# Uso: ./backup.sh

set -e

# Configurações
BACKUP_DIR="/root/backups"
DATA_DIR="/opt/lialean_server/data"
RETENTION_DAYS=7
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/lialean_backup_$DATE.tar.gz"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  LiaLean Server - Backup Automático${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Criar diretório de backup se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Criando diretório de backup...${NC}"
    mkdir -p "$BACKUP_DIR"
fi

# Verificar se o diretório de dados existe
if [ ! -d "$DATA_DIR" ]; then
    echo -e "${RED}ERRO: Diretório de dados não encontrado: $DATA_DIR${NC}"
    exit 1
fi

# Fazer backup
echo -e "${YELLOW}Iniciando backup...${NC}"
echo "Origem: $DATA_DIR"
echo "Destino: $BACKUP_FILE"
echo ""

tar -czf "$BACKUP_FILE" -C /opt lialean_server/data

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup concluído com sucesso!${NC}"
    echo "Tamanho: $BACKUP_SIZE"
    echo "Arquivo: $BACKUP_FILE"
else
    echo -e "${RED}✗ Erro ao criar backup${NC}"
    exit 1
fi

# Remover backups antigos
echo ""
echo -e "${YELLOW}Removendo backups com mais de $RETENTION_DAYS dias...${NC}"
find "$BACKUP_DIR" -name "lialean_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Listar backups existentes
echo ""
echo -e "${GREEN}Backups disponíveis:${NC}"
ls -lh "$BACKUP_DIR"/lialean_backup_*.tar.gz 2>/dev/null || echo "Nenhum backup encontrado"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backup finalizado!${NC}"
echo -e "${GREEN}========================================${NC}"

