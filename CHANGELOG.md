# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [4.0.0] - 2025-10-27

### Adicionado
- Guia completo único (GUIA_COMPLETO.md) com 22.000+ palavras
- Documentação de arquitetura (docs/ARCHITECTURE.md)
- Script de backup automático (scripts/backup.sh)
- Arquivo .gitignore completo
- Arquivo LICENSE (MIT)
- Arquivo CONTRIBUTING.md
- Suporte completo para Site LiaLean (React + Express + tRPC)
- Configuração de N8N com 3 containers (main, webhook, worker)
- Traefik v3.1 com SSL automático via Let's Encrypt
- Portainer CE para gerenciamento visual
- PostgreSQL 16 para N8N e Site LiaLean
- Redis 7 para cache e filas
- MariaDB 10.6 para WordPress
- WordPress (opcional)

### Corrigido
- Dockerfile do Site LiaLean: diretório patches/ não sendo copiado
- Dockerfile do Site LiaLean: pacote vite não encontrado em produção
- Dockerfile do Site LiaLean: caminhos de build do Vite incorretos
- Dockerfile do Site LiaLean: patch não copiado no stage de produção
- .dockerignore: diretório patches/ sendo ignorado
- docker-compose.yml: campo version obsoleto removido
- docker-compose.yml: variável N8N_USER_FOLDER adicionada
- docker-compose.yml: variável MARIADB_ROOT_PASSWORD adicionada
- .env.example: senha do Traefik agora entre aspas simples
- .env.example: todas as variáveis documentadas
- .env.example: instruções de geração de senhas completas
- Troubleshooting: 6 problemas documentados com soluções testadas
- DNS: avisos críticos sobre configuração antes do deploy
- Permissões do N8N: solução documentada

### Alterado
- Documentação consolidada em um único guia (GUIA_COMPLETO.md)
- README.md reformatado para padrão profissional do GitHub
- Estrutura de diretórios reorganizada
- Mapeamento de domínios: Site LiaLean em lialean.cloud, WordPress em wp.vps.lialean.cloud

### Removido
- Documentação fragmentada (múltiplos arquivos redundantes)
- Arquivos de configuração obsoletos

## [3.0.0] - 2025-10-26

### Adicionado
- Primeira versão com múltiplos arquivos de documentação

### Problemas Conhecidos
- Documentação fragmentada e redundante
- Arquivos Docker com erros
- Falta de troubleshooting detalhado

## [2.0.0] - 2025-10-25

### Adicionado
- Versão inicial com documentação básica

## [1.0.0] - 2025-10-24

### Adicionado
- Estrutura inicial do projeto

---

[4.0.0]: https://github.com/AgroIAActionPlan/config_server_v4/releases/tag/v4.0.0
[3.0.0]: https://github.com/AgroIAActionPlan/config_server_v4/releases/tag/v3.0.0
[2.0.0]: https://github.com/AgroIAActionPlan/config_server_v4/releases/tag/v2.0.0
[1.0.0]: https://github.com/AgroIAActionPlan/config_server_v4/releases/tag/v1.0.0

