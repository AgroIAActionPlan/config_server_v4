# Checklist de Implantação do Servidor LiaLean

Use este checklist para garantir que todos os passos foram executados corretamente.

## Pré-Implantação

- [ ] Servidor Ubuntu 24.04 provisionado e acessível via SSH
- [ ] Domínio principal (`lialean.cloud`) e subdomínios configurados no DNS
- [ ] Registros DNS propagados (verificar com `dig +short dominio.com`)
- [ ] Acesso root ou usuário com privilégios sudo

## Configuração Inicial do Sistema

- [ ] Sistema atualizado (`apt update && apt upgrade`)
- [ ] Firewall UFW configurado (portas 22, 80, 443)
- [ ] Fuso horário ajustado (`timedatectl set-timezone America/Sao_Paulo`)
- [ ] Usuário de trabalho criado e adicionado ao grupo sudo

## Instalação do Docker

- [ ] Repositório oficial do Docker adicionado
- [ ] Docker Engine e Docker Compose instalados
- [ ] Usuário adicionado ao grupo docker
- [ ] Instalação verificada (`docker --version`, `docker compose version`)

## Configuração da Stack

- [ ] Estrutura de diretórios criada em `/opt/lialean_server`
- [ ] Arquivo `.env` preenchido com todas as variáveis
- [ ] Senhas fortes geradas para todos os serviços
- [ ] Chave de criptografia N8N gerada (`openssl rand -hex 32`)
- [ ] Senha do Traefik criptografada com htpasswd
- [ ] Email válido configurado para ACME (Let's Encrypt)

## Deploy da Infraestrutura

- [ ] Docker Compose executado (`docker compose up -d`)
- [ ] Todos os containers iniciados com sucesso
- [ ] Logs do Traefik verificados (sem erros ACME)
- [ ] Certificados SSL emitidos para todos os domínios

## Configuração Pós-Deploy

- [ ] Bancos de dados criados no PostgreSQL (n8n_db, api_db)
- [ ] Usuários de banco de dados criados com permissões corretas
- [ ] Portainer acessível e configurado
- [ ] N8N acessível e login funcionando
- [ ] WordPress acessível e instalação inicial concluída

## Testes de Funcionamento

- [ ] Todos os domínios acessíveis via HTTPS (sem avisos de segurança)
- [ ] Dashboard do Traefik acessível e protegido por autenticação
- [ ] Dashboard do Portainer acessível
- [ ] Painel do N8N acessível e workflows podem ser criados
- [ ] Site WordPress carregando corretamente

## Segurança e Manutenção

- [ ] Arquivo `.env` com permissões restritas (`chmod 600`)
- [ ] Script de backup configurado e testado
- [ ] Cron job para backups automáticos criado (opcional)
- [ ] Monitoramento básico configurado (Uptime Kuma ou similar)
- [ ] Documentação salva em local seguro

## Troubleshooting Comum

### Erro de Porta 5432
- [ ] PostgreSQL do host parado (`systemctl stop postgresql`)
- [ ] PostgreSQL do host desabilitado (`systemctl disable postgresql`)

### Certificado SSL Não Emitido
- [ ] DNS propagado corretamente
- [ ] Portas 80 e 443 abertas no firewall
- [ ] Email ACME válido
- [ ] Logs do Traefik verificados

### Container Não Inicia
- [ ] Logs do container verificados (`docker logs nome_container`)
- [ ] Variáveis de ambiente corretas no `.env`
- [ ] Dependências (postgres, redis) rodando

## Próximos Passos

- [ ] Configurar backup automático
- [ ] Adicionar monitoramento avançado
- [ ] Configurar alertas por email/Slack
- [ ] Documentar workflows do N8N
- [ ] Personalizar WordPress (tema, plugins)
- [ ] Deploy de APIs customizadas

---

**Data da Implantação**: _______________
**Responsável**: _______________
**Observações**: 

