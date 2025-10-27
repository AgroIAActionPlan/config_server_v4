# Guia Definitivo para Configuração de Servidor Ubuntu 24 com Docker

**Autor**: Plinio Aquino
**Data**: 25 de Outubro de 2025

## 1. Introdução

Este guia fornece um passo a passo completo para configurar um servidor **Ubuntu 24.04** do zero, utilizando **Docker** para orquestrar múltiplos serviços de forma segura e eficiente. A arquitetura proposta utiliza **Traefik** como proxy reverso para gerenciamento automático de certificados **SSL/TLS** com **Let's Encrypt**, garantindo que todas as aplicações sejam servidas via HTTPS.

### 1.1. Arquitetura Proposta

A stack de serviços inclui:

- **Traefik**: Proxy reverso e load balancer.
- **Portainer**: Interface gráfica para gerenciamento de containers Docker.
- **PostgreSQL**: Banco de dados relacional para N8N e APIs.
- **Redis**: Banco de dados em memória para filas e cache.
- **N8N**: Plataforma de automação de workflows (instância principal, webhook e worker).
- **WordPress**: Sistema de gerenciamento de conteúdo (CMS).
- **Aplicações Customizadas**: Templates para APIs e apps Node.js.

### 1.2. Pré-requisitos

- Um servidor com **Ubuntu 24.04 LTS** recém-instalado.
- Acesso root ou um usuário com privilégios `sudo`.
- Um ou mais **domínios/subdomínios** apontados para o endereço IP do servidor.

---

## 2. Configuração Inicial do Servidor

Esta fase prepara o ambiente base do sistema operacional, incluindo atualizações, configuração de firewall e criação de um usuário de trabalho.

### 2.1. Acesso Inicial e Atualização do Sistema

Conecte-se ao seu servidor via SSH como `root` ou com o usuário `sudo` inicial.

```bash
ssh seu_usuario@IP_DO_SERVIDOR
```

Primeiro, atualize todos os pacotes do sistema para garantir que você tenha as últimas versões e patches de segurança.

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2. Configuração do Firewall (UFW)

Vamos configurar o **Uncomplicated Firewall (UFW)** para permitir apenas o tráfego essencial. Por padrão, todo o tráfego de entrada será negado.

```bash
# Permitir tráfego SSH (porta 22), HTTP (porta 80) e HTTPS (porta 443)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Habilitar o firewall
sudo ufw enable

# Verificar o status
sudo ufw status
```

O resultado deve mostrar que as portas 22, 80 e 443 estão permitidas.

### 2.3. Ajuste de Fuso Horário

Defina o fuso horário correto para o servidor. Isso é crucial para logs e tarefas agendadas.

```bash
sudo timedatectl set-timezone America/Sao_Paulo

# Verificar a configuração
timedatectl status
```

### 2.4. Criação de Usuário de Trabalho

Por questões de segurança, não é recomendado usar o usuário `root` para tarefas do dia a dia. Crie um usuário dedicado e adicione-o ao grupo `sudo`.

```bash
# Substitua 'deploy' pelo nome de usuário desejado
adduser deploy

# Adicionar o usuário ao grupo sudo
usermod -aG sudo deploy
```

> **Recomendação**: Configure o acesso SSH para este novo usuário utilizando chaves públicas/privadas e desabilite o login por senha para aumentar a segurança.

---

## 3. Instalação do Docker

Vamos instalar o **Docker Engine** e o **Docker Compose** a partir do repositório oficial do Docker para garantir que tenhamos a versão mais recente e estável.

### 3.1. Adicionar o Repositório Oficial do Docker

```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
```

### 3.2. Instalar o Docker Engine e Compose

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 3.3. Adicionar Usuário ao Grupo Docker

Para executar comandos Docker sem precisar usar `sudo` toda vez, adicione seu usuário de trabalho ao grupo `docker`.

```bash
# Substitua 'deploy' pelo seu usuário
sudo usermod -aG docker deploy

# Aplicar as novas permissões (faça logout e login novamente)
newgrp docker
```

### 3.4. Verificar a Instalação

Confirme que o Docker e o Docker Compose foram instalados corretamente.

```bash
docker --version
docker compose version
```

---


## 4. Estrutura de Diretórios e Configuração

Para manter o projeto organizado, escalável e fácil de gerenciar, adotaremos uma estrutura de diretórios padronizada no servidor, localizada em `/opt/lialean_server`.

### 4.1. Visão Geral da Estrutura

```plaintext
/opt/lialean_server/
├── stacks/               # Arquivos de configuração da stack Docker
│   ├── docker-compose.yml  # Orquestração de todos os serviços
│   └── .env                # Variáveis de ambiente e segredos
├── apps/                 # Código-fonte e Dockerfiles das suas aplicações
│   ├── wordpress/          # Arquivos específicos do WordPress (se customizado)
│   └── api-template/       # Template para novas APIs Node.js
├── data/                 # Dados persistentes dos containers (volumes)
│   ├── postgres/           # Dados do PostgreSQL
│   ├── redis/              # Dados do Redis
│   ├── n8n/                # Configurações e dados do N8N
│   ├── portainer/          # Dados do Portainer
│   ├── traefik/            # Certificados SSL (acme.json)
│   └── wordpress/          # Arquivos do WordPress (wp-content)
├── backups/              # Arquivos de backup (banco de dados, volumes)
└── logs/                 # Logs centralizados (opcional)
```



Segue um kit direto de comandos para criar exatamente essa estrutura no Ubuntu, já incluindo os arquivos vazios .env, docker-compose.yml e acme.json com permissões adequadas:

```bash
# 1) Criar toda a árvore de diretórios
sudo mkdir -p /opt/lialean_server/{stacks,apps/{wordpress,api-template},data/{postgres,redis,n8n,portainer,traefik,wordpress},backups,logs}

# 2) Criar os arquivos base da stack
sudo touch /opt/lialean_server/stacks/docker-compose.yml
sudo touch /opt/lialean_server/stacks/.env

# 3) Criar o arquivo do Traefik ACME (certificados) e aplicar permissões recomendadas
sudo touch /opt/lialean_server/data/traefik/acme.json
sudo chmod 600 /opt/lialean_server/data/traefik/acme.json

# 4) (Opcional) Definir dono padrão do diretório para seu usuário de deploy
#    Ajuste 'deploy:deploy' para o usuário/grupo que você usa no servidor
sudo chown -R deploy:deploy /opt/lialean_server

# 5) (Opcional) Para o acme.json convém manter root:root (o Traefik costuma rodar como root no container)
sudo chown root:root /opt/lialean_server/data/traefik/acme.json

# 6) (Opcional) Conferir o resultado com tree (instale se necessário)
sudo apt-get update && sudo apt-get install -y tree
tree -a /opt/lialean_server
```


### 4.2. Arquivos de Configuração Principais

- **`stacks/docker-compose.yml`**: É o coração da nossa infraestrutura. Este arquivo define todos os serviços (Traefik, N8N, WordPress, etc.), como eles se conectam (redes), onde armazenam seus dados (volumes) e como são expostos para o mundo exterior (labels do Traefik).

- **`stacks/.env`**: Este arquivo centraliza todas as variáveis de ambiente, como nomes de domínio, senhas, chaves de API e outras configurações. **Nunca adicione este arquivo a um repositório Git**, pois ele contém informações sensíveis.

---

## 5. Configuração das Variáveis de Ambiente (`.env`)

Antes de iniciar a stack, você precisa preencher o arquivo `.env` com suas informações específicas. Copie o conteúdo abaixo para `/opt/lialean_server/stacks/.env` e substitua os valores de exemplo.

> **Atenção**: Para senhas e chaves, sempre use valores longos, aleatórios e únicos. Você pode usar um gerenciador de senhas ou o comando `openssl rand -base64 32` para gerá-los.

```bash
# Crie o diretório e o arquivo
mkdir -p /opt/lialean_server/stacks
nano /opt/lialean_server/stacks/.env
```

Cole e edite o conteúdo que foi gerado anteriormente em `/home/ubuntu/lialean_server/stacks/.env`.

### 5.1. Gerando Segredos

- **Senhas**: Para cada variável de senha (ex: `POSTGRES_PASSWORD`), gere uma string aleatória:
  ```bash
  openssl rand -base64 32
  ```

- **Chave de Criptografia N8N**: Use o formato hexadecimal:
  ```bash
  openssl rand -hex 32
  ```

- **Autenticação do Traefik**: A senha para o dashboard do Traefik precisa ser criptografada com `htpasswd`. Você pode usar um gerador online ou o utilitário de linha de comando. O formato final deve ser `usuario:$apr1$hash`.

---


## 6. Orquestração com Docker Compose

O arquivo `docker-compose.yml` gerencia toda a nossa stack. Ele está configurado para seguir as melhores práticas de 2025, incluindo:

- **Redes Segregadas**: Uma rede `proxy` para tráfego externo (gerenciada pelo Traefik) e uma rede `internal` para a comunicação entre serviços, que não é acessível de fora.
- **Healthchecks**: Cada serviço crítico (PostgreSQL, Redis, etc.) possui uma verificação de saúde para que o Docker possa reiniciar containers que não estão funcionando corretamente.
- **Segurança**: Containers são configurados para rodar com privilégios mínimos (`no-new-privileges:true`).
- **Labels para Traefik**: As `labels` em cada serviço instruem o Traefik sobre como expor aquele serviço, qual domínio usar e como aplicar o certificado SSL.

### 6.1. Iniciando a Stack Principal

Com o arquivo `.env` devidamente preenchido, navegue até o diretório `stacks` e inicie todos os serviços em modo "detached" (`-d`).

```bash
cd /opt/lialean_server/stacks
docker compose up -d
```

O Docker irá baixar todas as imagens necessárias e iniciar os containers. Este processo pode levar alguns minutos na primeira vez.

### 6.2. Verificando o Status dos Serviços

Após a inicialização, verifique se todos os containers estão rodando e saudáveis.

```bash
# Listar todos os containers da stack
docker compose ps

# Visualizar logs do Traefik para verificar a emissão dos certificados
docker logs traefik
```

Se tudo correu bem, você deverá ver logs no Traefik indicando que os certificados para seus domínios foram gerados com sucesso. Em poucos minutos, você poderá acessar os painéis do **Portainer**, **Traefik** e **N8N** nos domínios que você configurou.

---

## 7. Configuração Pós-Deploy

Com a infraestrutura rodando, precisamos criar os bancos de dados específicos para cada aplicação dentro do nosso servidor PostgreSQL.

### 7.1. Criação dos Bancos de Dados Adicionais

Com a infraestrutura rodando, precisamos criar os bancos de dados para as aplicações que utilizarão o **PostgreSQL**, como o N8N e as APIs customizadas. O WordPress utilizará um banco de dados **MariaDB** separado, que é configurado automaticamente pelo seu próprio container.

> **Nota sobre a Escolha do Banco de Dados**: A stack utiliza PostgreSQL para aplicações modernas como N8N e APIs, que se beneficiam de seus recursos avançados. Para o WordPress, utilizamos MariaDB, que é o padrão da comunidade, garantindo máxima compatibilidade e performance com a imagem Docker oficial, evitando a necessidade de plugins ou configurações complexas.

Execute o comando abaixo para entrar no container do PostgreSQL e criar os bancos de dados e usuários necessários. Substitua as senhas pelos mesmos valores que você definiu no arquivo `.env`.

```bash
# Conectar ao container do PostgreSQL
docker exec -it postgres psql -U postgres
```

Dentro do `psql`, execute os seguintes comandos SQL:

```sql
-- Banco de dados para N8N
CREATE DATABASE n8n_db;
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'SENHA_FORTE_PARA_N8N_DB';
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO n8n_user;

-- Banco de dados para a API genérica (exemplo)
CREATE DATABASE api_db;
CREATE USER api_user WITH ENCRYPTED PASSWORD 'SENHA_FORTE_PARA_API_DB';
GRANT ALL PRIVILEGES ON DATABASE api_db TO api_user;

-- Listar bancos para confirmar a criação
\l

-- Sair do psql
\q
```

---

## 8. Deploy de Aplicações Customizadas

Este guia inclui templates de `Dockerfile` para **WordPress** e uma **API Node.js**, localizados em `/opt/lialean_server/apps/`.

### 8.1. Deploy de uma API Node.js

1.  **Copie seu código-fonte** para um novo diretório dentro de `/opt/lialean_server/apps/`.
2.  **Use o `Dockerfile` do `api-template`** como base, ajustando-o se necessário.
3.  **Adicione um novo serviço** ao seu arquivo `docker-compose.yml` principal. Use o serviço do WordPress como modelo, ajustando o nome do serviço, o `build context`, o domínio (`rule`) e a porta do serviço.

    ```yaml
    # Exemplo de serviço para a nova API no docker-compose.yml
    minha-api:
      build:
        context: ../apps/minha-api
      container_name: minha-api
      restart: unless-stopped
      networks:
        - proxy
        - internal
      depends_on:
        - postgres
      environment:
        - DATABASE_URL=postgresql://api_user:SENHA_FORTE_PARA_API_DB@postgres:5432/api_db
        # Outras variáveis de ambiente
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.minha-api.rule=Host(`minha-api.seusite.com`)"
        - "traefik.http.routers.minha-api.entrypoints=websecure"
        - "traefik.http.routers.minha-api.tls.certresolver=letsencrypt"
        - "traefik.http.services.minha-api.loadbalancer.server.port=3000"
    ```

4.  **Faça o deploy da stack atualizada**:

    ```bash
    cd /opt/lialean_server/stacks
    docker compose up -d --build minha-api
    ```

O Traefik detectará o novo serviço automaticamente e obterá um certificado SSL para ele.

---

## 9. Manutenção e Boas Práticas

- **Backups**: Implemente scripts de backup para os volumes de dados (especialmente `postgres`, `wordpress` e `n8n`). Agende-os com `cron` para rodar automaticamente.
- **Atualizações**: Para atualizar um serviço, altere a tag da imagem no `docker-compose.yml` e execute `docker compose up -d --build <nome_do_servico>`.
- **Monitoramento**: Use o dashboard do Traefik e do Portainer para monitorar a saúde dos containers. Para uma solução mais robusta, considere adicionar um container do [Uptime Kuma](https://github.com/louislam/uptime-kuma) à stack.
- **Segurança**: Mantenha o sistema operacional e as imagens Docker sempre atualizadas. Revise periodicamente as configurações de firewall e as permissões de usuário.

---

## 10. Troubleshooting

- **Erro de porta 5432 (PostgreSQL)**: Este erro geralmente ocorre se já existe uma instância do PostgreSQL rodando diretamente no host. A solução é parar e desabilitar o serviço do PostgreSQL do host (`sudo systemctl stop postgresql` e `sudo systemctl disable postgresql`) ou garantir que o `docker-compose.yml` não está mapeando a porta 5432 para o host.

- **Tela Vermelha de Segurança (Erro de SSL)**: Geralmente indica que o Traefik não conseguiu emitir um certificado. Verifique:
    1.  Se seus domínios estão apontando corretamente para o IP do servidor.
    2.  Se as portas 80 e 443 estão abertas no firewall (UFW).
    3.  Os logs do Traefik (`docker logs traefik`) para mensagens de erro do Let's Encrypt.
    4.  Se o email no arquivo `.env` (`ACME_EMAIL`) é válido.



## 11. Conclusão

Seguindo este guia, você terá uma infraestrutura robusta, segura e escalável, totalmente gerenciada por Docker e Traefik. A arquitetura modular permite adicionar, remover ou atualizar serviços com o mínimo de esforço, enquanto o proxy reverso com SSL automático garante a segurança das comunicações. Lembre-se de manter o sistema e as imagens Docker atualizadas e de realizar backups regulares para garantir a integridade dos seus dados.

---

## 12. Referências

1.  **Docker Documentation**: [Building best practices](https://docs.docker.com/build/building/best-practices/)
2.  **Talent500**: [Modern Docker Best Practices for 2025](https://talent500.com/blog/modern-docker-best-practices-2025/)
3.  **Traefik Documentation**: [Traefik & ACME Certificates Resolver](https://doc.traefik.io/traefik/https/acme/)
4.  **Docker Blog**: [How to Dockerize WordPress](https://www.docker.com/blog/how-to-dockerize-wordpress/)
5.  **OWASP Cheat Sheet Series**: [NodeJS Docker Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/NodeJS_Docker_Cheat_Sheet.html)

