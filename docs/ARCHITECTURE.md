# Arquitetura do LiaLean Server

## Visão Geral

O LiaLean Server é uma infraestrutura Docker completa que hospeda múltiplos serviços integrados, com foco em segurança, escalabilidade e facilidade de manutenção.

---

## Diagrama de Arquitetura

```
                                   Internet
                                       |
                                       | (80/443)
                                       ↓
                              ┌─────────────────┐
                              │    Traefik      │
                              │  (Proxy + SSL)  │
                              └─────────────────┘
                                       |
                    ┌──────────────────┼──────────────────┐
                    |                  |                  |
          ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
          │ Site LiaLean│    │     N8N     │    │  Portainer  │
          │  (React +   │    │ (Automation)│    │(Management) │
          │   Express)  │    └─────────────┘    └─────────────┘
          └─────────────┘            |
                  |                  |
                  └──────────┬───────┘
                             |
                    ┌────────┴────────┐
                    |                 |
          ┌─────────────┐    ┌─────────────┐
          │ PostgreSQL  │    │    Redis    │
          │  (N8N +     │    │   (Cache)   │
          │   LiaLean)  │    └─────────────┘
          └─────────────┘
```

---

## Componentes

### 1. Traefik (Proxy Reverso)

**Função**: Gateway de entrada para todos os serviços.

**Responsabilidades**:
- Roteamento de requisições HTTP/HTTPS
- Emissão e renovação automática de certificados SSL (Let's Encrypt)
- Redirecionamento HTTP → HTTPS
- Load balancing (se necessário)

**Portas**:
- 80 (HTTP)
- 443 (HTTPS)
- 8080 (Dashboard - apenas interno)

**Volumes**:
- `/opt/lialean_server/data/traefik/acme.json` - Certificados SSL

---

### 2. Site LiaLean

**Função**: Aplicação web institucional full-stack.

**Tecnologias**:
- Frontend: React 19 + Vite
- Backend: Express 4 + tRPC 11
- Banco de Dados: PostgreSQL 16

**Portas**:
- 3000 (interna)

**Volumes**:
- Nenhum (stateless)

**Banco de Dados**:
- Nome: `lialean_site_db`
- Usuário: `lialean_user`

---

### 3. N8N (Automação)

**Função**: Plataforma de automação de workflows.

**Arquitetura**:
- **n8n-main**: Interface web e execução de workflows síncronos
- **n8n-webhook**: Recepção de webhooks externos
- **n8n-worker**: Execução de workflows assíncronos

**Portas**:
- 5678 (interna)

**Volumes**:
- `/opt/lialean_server/data/n8n` - Dados e configurações

**Banco de Dados**:
- Nome: `n8n_db`
- Usuário: `n8n_user`

---

### 4. PostgreSQL

**Função**: Banco de dados relacional principal.

**Versão**: 16 (Alpine)

**Portas**:
- 5432 (apenas rede interna Docker)

**Volumes**:
- `/opt/lialean_server/data/postgres` - Dados persistentes

**Bancos de Dados**:
1. `n8n_db` - N8N
2. `lialean_site_db` - Site LiaLean

---

### 5. Redis

**Função**: Cache em memória e filas de mensagens.

**Versão**: 7 (Alpine)

**Portas**:
- 6379 (apenas rede interna Docker)

**Volumes**:
- `/opt/lialean_server/data/redis` - Dados persistentes

---

### 6. WordPress (Opcional)

**Função**: CMS para blog ou conteúdo adicional.

**Versão**: Latest (Apache + PHP)

**Portas**:
- 80 (interna)

**Volumes**:
- `/opt/lialean_server/data/wordpress` - Arquivos do WordPress

**Banco de Dados**:
- Nome: `wordpress`
- Usuário: `wordpress`
- SGBD: MariaDB

---

### 7. MariaDB

**Função**: Banco de dados para WordPress.

**Versão**: 10.6

**Portas**:
- 3306 (apenas rede interna Docker)

**Volumes**:
- `/opt/lialean_server/data/mariadb` - Dados persistentes

---

### 8. Portainer

**Função**: Interface web para gerenciamento de containers.

**Versão**: CE (Community Edition)

**Portas**:
- 9000 (interna)

**Volumes**:
- `/opt/lialean_server/data/portainer` - Dados persistentes
- `/var/run/docker.sock` - Socket do Docker

---

## Redes Docker

### Rede `proxy` (Bridge)

**Função**: Rede pública para serviços expostos via Traefik.

**Containers**:
- traefik
- lialean-site
- n8n-main
- n8n-webhook
- portainer
- wordpress

---

### Rede `internal` (Bridge)

**Função**: Rede privada para comunicação entre serviços internos.

**Containers**:
- postgres
- redis
- mariadb
- n8n-main
- n8n-webhook
- n8n-worker
- lialean-site
- wordpress

---

## Segurança

### Firewall (UFW)

Apenas 3 portas abertas:
- 22 (SSH)
- 80 (HTTP - redireciona para HTTPS)
- 443 (HTTPS)

### Isolamento de Rede

- Bancos de dados **não** são expostos ao host
- Comunicação interna via rede Docker privada
- Apenas Traefik tem acesso à rede pública

### Autenticação

- **Traefik Dashboard**: HTTP Basic Auth
- **N8N**: HTTP Basic Auth
- **Portainer**: Usuário/senha próprio
- **WordPress**: Usuário/senha próprio

### SSL/TLS

- Certificados emitidos automaticamente pelo Let's Encrypt
- Renovação automática a cada 90 dias
- Redirecionamento HTTP → HTTPS forçado

---

## Escalabilidade

### Horizontal

- **N8N**: Já configurado com 3 containers (main, webhook, worker)
- **Site LiaLean**: Pode ser escalado com `docker compose scale lialean-site=3`

### Vertical

- Ajustar recursos no `docker-compose.yml`:
  ```yaml
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
  ```

---

## Backup e Recuperação

### Dados Persistentes

Todos os volumes estão em `/opt/lialean_server/data/`:
- `postgres/` - Banco de dados PostgreSQL
- `redis/` - Cache Redis
- `n8n/` - Configurações e workflows N8N
- `mariadb/` - Banco de dados MariaDB
- `wordpress/` - Arquivos WordPress
- `traefik/acme.json` - Certificados SSL
- `portainer/` - Configurações Portainer

### Script de Backup

```bash
/opt/lialean_server/scripts/backup.sh
```

Cria um arquivo `.tar.gz` com todos os dados e remove backups com mais de 7 dias.

### Recuperação

```bash
cd /opt
tar -xzvf backup_YYYY-MM-DD.tar.gz
docker compose restart
```

---

## Monitoramento

### Logs

```bash
# Ver logs de todos os serviços
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f nome_do_servico
```

### Healthchecks

Containers com healthcheck configurado:
- postgres
- redis
- mariadb
- lialean-site

Verificar status:
```bash
docker compose ps
```

---

## Manutenção

### Atualização de Imagens

```bash
docker compose pull
docker compose up -d
```

### Limpeza de Recursos Não Utilizados

```bash
docker system prune -a --volumes
```

**⚠️ ATENÇÃO**: Isso remove **todos** os volumes não utilizados. Faça backup antes!

---

## Referências

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [N8N Documentation](https://docs.n8n.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

