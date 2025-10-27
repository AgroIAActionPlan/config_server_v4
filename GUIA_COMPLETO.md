# Guia Completo: Servidor Ubuntu 24 com Docker para LiaLean

**Versão**: 4.0 Final  
**Data**: 27 de outubro de 2025  
**Status**: Testado e Validado em Produção

---

## Índice

1. [Introdução](#1-introdução)
2. [Arquitetura](#2-arquitetura)
3. [Pré-requisitos](#3-pré-requisitos)
4. [Configuração Inicial do Servidor](#4-configuração-inicial-do-servidor)
5. [Instalação do Docker](#5-instalação-do-docker)
6. [Configuração do DNS](#6-configuração-do-dns)
7. [Preparação dos Arquivos](#7-preparação-dos-arquivos)
8. [Configuração das Variáveis de Ambiente](#8-configuração-das-variáveis-de-ambiente)
9. [Deploy da Stack](#9-deploy-da-stack)
10. [Configuração dos Bancos de Dados](#10-configuração-dos-bancos-de-dados)
11. [Validação e Testes](#11-validação-e-testes)
12. [Troubleshooting](#12-troubleshooting)
13. [Manutenção](#13-manutenção)
14. [Referências](#14-referências)

---

## 1. Introdução

Este guia fornece instruções completas e testadas para configurar um servidor Ubuntu 24.04 com Docker, hospedando múltiplos serviços com SSL automático via Traefik.

### 1.1. O Que Será Instalado

- **Traefik v3.1**: Proxy reverso com SSL automático (Let's Encrypt)
- **Portainer CE**: Gerenciamento visual de containers
- **PostgreSQL 16**: Banco de dados para N8N e Site LiaLean
- **Redis 7**: Cache e filas de mensagens
- **N8N**: Automação de workflows (3 containers: main, webhook, worker)
- **MariaDB 10.6**: Banco de dados para WordPress
- **WordPress**: CMS (opcional)
- **Site LiaLean**: Aplicação full-stack (React + Express + tRPC)

### 1.2. Tempo Estimado

- Configuração inicial: 30 minutos
- Deploy e configuração: 45 minutos
- **Total**: ~1h15min

---

## 2. Arquitetura

### 2.1. Mapeamento de Domínios

| Domínio | Serviço | Porta Interna |
|---------|---------|---------------|
| `lialean.cloud` | Site LiaLean | 3000 |
| `www.lialean.cloud` | Redirect → lialean.cloud | - |
| `n8n.vps.lialean.cloud` | N8N Main | 5678 |
| `webhook.vps.lialean.cloud` | N8N Webhook | 5678 |
| `portainer.vps.lialean.cloud` | Portainer | 9000 |
| `traefik.vps.lialean.cloud` | Traefik Dashboard | 8080 |
| `wp.vps.lialean.cloud` | WordPress | 80 |

### 2.2. Redes Docker

- **proxy**: Rede pública (Traefik + serviços web)
- **internal**: Rede privada (bancos de dados + Redis)

### 2.3. Volumes Persistentes

```
/opt/lialean_server/data/
├── postgres/       # Dados do PostgreSQL
├── redis/          # Dados do Redis
├── n8n/            # Dados do N8N
├── mariadb/        # Dados do MariaDB
├── wordpress/      # Arquivos do WordPress
├── traefik/        # Certificados SSL (acme.json)
└── portainer/      # Dados do Portainer
```

---

## 3. Pré-requisitos

Antes de iniciar, certifique-se de ter:

- [ ] Servidor com **Ubuntu 24.04 LTS** recém-instalado
- [ ] Acesso root ou usuário com privilégios `sudo`
- [ ] **Domínios registrados** (ex: `lialean.cloud`)
- [ ] Acesso ao painel DNS do provedor de domínio
- [ ] Conexão SSH estável com o servidor
- [ ] IP público do servidor anotado

---

## 4. Configuração Inicial do Servidor

### 4.1. Conectar ao Servidor

```bash
ssh root@SEU_IP_DO_SERVIDOR
```

### 4.2. Atualizar o Sistema

```bash
apt update && apt upgrade -y
```

### 4.3. Configurar Firewall (UFW)

```bash
# Permitir SSH, HTTP e HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Habilitar firewall
ufw enable

# Verificar status
ufw status
```

**Saída esperada**:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

### 4.4. Configurar Fuso Horário

```bash
timedatectl set-timezone America/Sao_Paulo
timedatectl status
```

### 4.5. Desabilitar PostgreSQL do Host (Se Existir)

```bash
# Verificar se existe
systemctl status postgresql

# Se estiver rodando, parar e desabilitar
systemctl stop postgresql
systemctl disable postgresql
```

---

## 5. Instalação do Docker

### 5.1. Adicionar Repositório Oficial do Docker

```bash
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
```

### 5.2. Instalar Docker Engine e Compose

```bash
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 5.3. Verificar Instalação

```bash
docker --version
docker compose version
```

**Saída esperada**:
```
Docker version 27.x.x, build ...
Docker Compose version v2.x.x
```

---

## 6. Configuração do DNS

**⚠️ CRÍTICO**: Configure o DNS **ANTES** de iniciar os containers. Sem DNS correto, o Traefik não conseguirá emitir certificados SSL.

### 6.1. Obter o IP do Servidor

```bash
curl -4 ifconfig.me
```

Anote o IP retornado (ex: `72.61.132.113`).

### 6.2. Configurar Registros DNS

Acesse o painel DNS do seu provedor e adicione:

#### Registro A para o Servidor

```
Tipo: A
Nome: vps
Conteúdo: SEU_IP_DO_SERVIDOR
TTL: 300
```

#### Registro A para o Domínio Raiz

```
Tipo: A
Nome: @ (ou deixe em branco)
Conteúdo: SEU_IP_DO_SERVIDOR
TTL: 300
```

#### Registro CNAME para www

```
Tipo: CNAME
Nome: www
Conteúdo: lialean.cloud
TTL: 300
```

#### Registros CNAME para Subdomínios

```
Tipo: CNAME
Nome: n8n.vps
Conteúdo: vps.lialean.cloud
TTL: 300

Tipo: CNAME
Nome: webhook.vps
Conteúdo: vps.lialean.cloud
TTL: 300

Tipo: CNAME
Nome: portainer.vps
Conteúdo: vps.lialean.cloud
TTL: 300

Tipo: CNAME
Nome: traefik.vps
Conteúdo: vps.lialean.cloud
TTL: 300

Tipo: CNAME
Nome: wp.vps
Conteúdo: vps.lialean.cloud
TTL: 300
```

### 6.3. Verificar Propagação do DNS

Aguarde 5-30 minutos e verifique:

```bash
dig +short lialean.cloud
dig +short www.lialean.cloud
dig +short n8n.vps.lialean.cloud
dig +short portainer.vps.lialean.cloud
```

**Todos devem retornar o IP do seu servidor**.

---

## 7. Preparação dos Arquivos

### 7.1. Criar Estrutura de Diretórios

```bash
mkdir -p /opt/lialean_server/{stacks,apps,scripts,docs,data/{postgres,redis,n8n,mariadb,wordpress,traefik,portainer}}
cd /opt/lialean_server
```

### 7.2. Fazer Upload dos Arquivos

**Opção A**: Fazer upload do pacote ZIP fornecido:

```bash
# No seu computador local
scp lialean_server_final.zip root@SEU_IP:/tmp/

# No servidor
cd /opt/lialean_server
unzip /tmp/lialean_server_final.zip
```

**Opção B**: Clonar o repositório do site:

```bash
cd /opt/lialean_server/apps
git clone https://github.com/AgroIAActionPlan/Site_LiaLean.git lialean-site
```

E criar os arquivos `docker-compose.yml`, `.env`, `Dockerfile` manualmente (fornecidos neste guia).

### 7.3. Criar Arquivo acme.json para o Traefik

```bash
touch /opt/lialean_server/data/traefik/acme.json
chmod 600 /opt/lialean_server/data/traefik/acme.json
```

---

## 8. Configuração das Variáveis de Ambiente

### 8.1. Criar Arquivo .env

```bash
cd /opt/lialean_server/stacks
nano .env
```

### 8.2. Preencher o Arquivo .env

Cole o conteúdo abaixo e **substitua TODOS os valores** marcados com `ALTERAR_AQUI`:

```bash
# ========================================
# Configuração Geral
# ========================================
TIMEZONE=America/Sao_Paulo
ROOT_DOMAIN=vps.lialean.cloud

# ========================================
# Traefik - Proxy Reverso e SSL
# ========================================
TRAEFIK_HOSTNAME=traefik.${ROOT_DOMAIN}
ACME_EMAIL=seu-email@exemplo.com  # ALTERAR_AQUI

# Gerar com: htpasswd -nb admin sua_senha
# IMPORTANTE: Use aspas simples!
TRAEFIK_BASIC_AUTH='admin:$apr1$ALTERAR_AQUI'  # ALTERAR_AQUI

# ========================================
# Portainer
# ========================================
PORTAINER_HOSTNAME=portainer.${ROOT_DOMAIN}

# ========================================
# PostgreSQL
# ========================================
POSTGRES_PASSWORD=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32

# ========================================
# N8N
# ========================================
N8N_HOSTNAME=n8n.${ROOT_DOMAIN}
N8N_WEBHOOK_HOSTNAME=webhook.${ROOT_DOMAIN}
N8N_BASIC_USER=admin
N8N_BASIC_PASS=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32
N8N_DB_NAME=n8n_db
N8N_DB_USER=n8n_user
N8N_DB_PASSWORD=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32
N8N_ENCRYPTION_KEY=ALTERAR_AQUI  # Gerar com: openssl rand -hex 32

# ========================================
# MariaDB
# ========================================
MARIADB_ROOT_PASSWORD=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32

# ========================================
# WordPress
# ========================================
WP_HOSTNAME=wp.${ROOT_DOMAIN}
WP_DB_NAME=wordpress
WP_DB_USER=wordpress
WP_DB_PASSWORD=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32

# ========================================
# Site LiaLean
# ========================================
LIALEAN_DB_NAME=lialean_site_db
LIALEAN_DB_USER=lialean_user
LIALEAN_DB_PASSWORD=ALTERAR_AQUI  # Gerar com: openssl rand -base64 32
LIALEAN_JWT_SECRET=ALTERAR_AQUI  # Gerar com: openssl rand -hex 32
LIALEAN_SITE_TITLE=LiaLean - Inteligência Artificial para o Agronegócio
LIALEAN_SITE_LOGO=/assets/logo.svg
```

### 8.3. Gerar Senhas e Chaves

#### Senhas Gerais (base64)

```bash
openssl rand -base64 32
```

Copie e cole no `.env` para:
- `POSTGRES_PASSWORD`
- `N8N_BASIC_PASS`
- `N8N_DB_PASSWORD`
- `MARIADB_ROOT_PASSWORD`
- `WP_DB_PASSWORD`
- `LIALEAN_DB_PASSWORD`

#### Chaves Hex (32 bytes = 64 caracteres)

```bash
openssl rand -hex 32
```

Copie e cole no `.env` para:
- `N8N_ENCRYPTION_KEY`
- `LIALEAN_JWT_SECRET`

#### Senha do Traefik (htpasswd)

```bash
# Instalar htpasswd
apt install -y apache2-utils

# Gerar senha (substitua 'admin' e 'sua_senha_forte')
htpasswd -nb admin sua_senha_forte
```

Copie o resultado (ex: `admin:$apr1$QppNSjJe$...`) e cole no `.env` **entre aspas simples**:

```bash
TRAEFIK_BASIC_AUTH='admin:$apr1$QppNSjJe$...'
```

### 8.4. Salvar e Sair

Pressione `Ctrl+O`, `Enter`, `Ctrl+X`.

---

## 9. Deploy da Stack

### 9.1. Criar docker-compose.yml

```bash
cd /opt/lialean_server/stacks
nano docker-compose.yml
```

Cole o conteúdo completo fornecido no arquivo `stacks/docker-compose.yml` deste repositório.

### 9.2. Iniciar Todos os Containers

```bash
cd /opt/lialean_server/stacks
docker compose up -d
```

**Saída esperada**:
```
[+] Running 11/11
 ✔ Network proxy          Created
 ✔ Network internal       Created
 ✔ Container traefik      Started
 ✔ Container portainer    Started
 ✔ Container postgres     Started
 ✔ Container redis        Started
 ✔ Container mariadb      Started
 ✔ Container n8n-main     Started
 ✔ Container n8n-webhook  Started
 ✔ Container n8n-worker   Started
 ✔ Container wordpress    Started
 ✔ Container lialean-site Started
```

### 9.3. Verificar Status dos Containers

```bash
docker compose ps
```

**Todos devem estar com status `Up`**.

### 9.4. Monitorar Emissão de Certificados SSL

```bash
docker logs traefik | grep -i "certificate"
```

Aguarde 1-2 minutos. Você deve ver mensagens como:
```
"Certificates obtained for domains [n8n.vps.lialean.cloud]"
"Certificates obtained for domains [portainer.vps.lialean.cloud]"
...
```

---

## 10. Configuração dos Bancos de Dados

### 10.1. Criar Banco de Dados do N8N

```bash
docker exec -it postgres psql -U postgres
```

Dentro do PostgreSQL, execute:

```sql
CREATE DATABASE n8n_db;
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'SUA_SENHA_DO_ENV';
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO n8n_user;
\c n8n_db
GRANT ALL ON SCHEMA public TO n8n_user;
\q
```

> **IMPORTANTE**: Substitua `'SUA_SENHA_DO_ENV'` pela senha definida em `N8N_DB_PASSWORD` no arquivo `.env`.

Para ver a senha:
```bash
grep N8N_DB_PASSWORD /opt/lialean_server/stacks/.env
```

### 10.2. Criar Banco de Dados do Site LiaLean

```bash
docker exec -it postgres psql -U postgres
```

Dentro do PostgreSQL, execute:

```sql
CREATE DATABASE lialean_site_db;
CREATE USER lialean_user WITH ENCRYPTED PASSWORD 'SUA_SENHA_DO_ENV';
GRANT ALL PRIVILEGES ON DATABASE lialean_site_db TO lialean_user;
\c lialean_site_db
GRANT ALL ON SCHEMA public TO lialean_user;
\q
```

> **IMPORTANTE**: Substitua `'SUA_SENHA_DO_ENV'` pela senha definida em `LIALEAN_DB_PASSWORD` no arquivo `.env`.

### 10.3. Reiniciar Serviços

```bash
cd /opt/lialean_server/stacks
docker compose restart n8n-main n8n-webhook n8n-worker lialean-site
```

---

## 11. Validação e Testes

### 11.1. Verificar Status de Todos os Containers

```bash
docker compose ps
```

**Todos devem estar `Up` e nenhum `Restarting`**.

### 11.2. Testar Acesso via Navegador

Abra um navegador e acesse:

| URL | Esperado |
|-----|----------|
| `https://lialean.cloud` | Site LiaLean carrega |
| `https://n8n.vps.lialean.cloud` | Pede autenticação (admin / senha do .env) |
| `https://portainer.vps.lialean.cloud` | Pede para criar usuário admin |
| `https://traefik.vps.lialean.cloud` | Pede autenticação (admin / senha do .env) |
| `https://wp.vps.lialean.cloud` | Tela de instalação do WordPress |

### 11.3. Verificar Certificados SSL

Todos os sites devem mostrar **cadeado verde** no navegador.

Se aparecer "Site perigoso" (tela vermelha):
1. Limpe o cache do navegador (Ctrl+Shift+Delete)
2. OU abra em aba anônima (Ctrl+Shift+N)
3. OU aguarde mais 5 minutos para o certificado propagar

---

## 12. Troubleshooting

### 12.1. Erro: DNS_PROBE_FINISHED_NXDOMAIN

**Causa**: DNS não configurado ou não propagado.

**Solução**:
```bash
dig +short seu_dominio.com
```

Se não retornar o IP do servidor, verifique a configuração DNS e aguarde propagação.

---

### 12.2. Erro: Tela Vermelha "Site Perigoso"

**Causa**: Certificado SSL não emitido ou cache do navegador.

**Solução**:
1. Verificar logs do Traefik:
   ```bash
   docker logs traefik | grep -i "certificate"
   ```

2. Se não houver certificados, verificar DNS:
   ```bash
   dig +short seu_dominio.com
   ```

3. Se DNS estiver correto, limpar `acme.json` e reiniciar:
   ```bash
   docker compose stop traefik
   rm /opt/lialean_server/data/traefik/acme.json
   touch /opt/lialean_server/data/traefik/acme.json
   chmod 600 /opt/lialean_server/data/traefik/acme.json
   docker compose up -d traefik
   ```

---

### 12.3. Erro: N8N - EACCES permission denied

**Causa**: Permissões incorretas no diretório de dados do N8N.

**Solução**:
```bash
docker compose stop n8n-main n8n-webhook n8n-worker
rm -rf /opt/lialean_server/data/n8n/*
mkdir -p /opt/lialean_server/data/n8n
chown -R 1000:1000 /opt/lialean_server/data/n8n
docker compose up -d n8n-main n8n-webhook n8n-worker
```

---

### 12.4. Erro: Rate Limit do Let's Encrypt

**Mensagem nos logs**: `too many failed authorizations`

**Causa**: Múltiplas tentativas falhas de emissão de certificado.

**Solução**:
1. **Corrija o DNS primeiro**
2. Aguarde 1 hora desde a última tentativa
3. OU limpe `acme.json` (após DNS correto)

---

### 12.5. Container Reiniciando Continuamente

**Verificar logs**:
```bash
docker logs nome_do_container --tail 100
```

**Causas comuns**:
- Banco de dados não criado
- Variáveis de ambiente incorretas
- Permissões de arquivo

---

## 13. Manutenção

### 13.1. Atualizar a Stack

```bash
cd /opt/lialean_server/stacks
docker compose pull
docker compose up -d
```

### 13.2. Backup dos Dados

```bash
cd /opt
tar -czvf /root/backups/lialean_server_data_$(date +%F).tar.gz lialean_server/data
```

### 13.3. Ver Logs de um Serviço

```bash
docker compose logs -f nome_do_servico
```

### 13.4. Reiniciar um Serviço

```bash
docker compose restart nome_do_servico
```

### 13.5. Parar Todos os Serviços

```bash
docker compose down
```

---

## 14. Referências

- [Documentação Oficial do Docker](https://docs.docker.com/)
- [Documentação Oficial do Traefik](https://doc.traefik.io/traefik/)
- [Documentação Oficial do N8N](https://docs.n8n.io/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

---

**Fim do Guia Completo**

Se encontrar problemas não documentados aqui, consulte os logs dos containers e verifique a seção de Troubleshooting.

