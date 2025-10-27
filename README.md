# LiaLean Server - Infraestrutura Docker Completa

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](https://github.com/AgroIAActionPlan/config_server_v4/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-compose-blue.svg)](https://docs.docker.com/compose/)
[![Ubuntu](https://img.shields.io/badge/ubuntu-24.04-orange.svg)](https://ubuntu.com/)
[![Status](https://img.shields.io/badge/status-production-success.svg)](https://github.com/AgroIAActionPlan/config_server_v4)

**Versão**: 4.0 Final  
**Status**: Produção  
**Licença**: MIT

---

## 📋 Sobre

Infraestrutura completa e testada para hospedar o ecossistema LiaLean em um servidor Ubuntu 24.04 com Docker, incluindo:

- **Site institucional** (React + Express + tRPC)
- **N8N** (automação de workflows)
- **WordPress** (CMS opcional)
- **Traefik** (proxy reverso + SSL automático)
- **Portainer** (gerenciamento de containers)
- **PostgreSQL** e **MariaDB** (bancos de dados)
- **Redis** (cache e filas)

---

## 🚀 Início Rápido

### Pré-requisitos

- Ubuntu 24.04 LTS
- Domínio configurado no DNS
- Acesso root ou sudo

### Instalação

```bash
# 1. Clonar ou fazer download deste repositório
cd /opt
git clone https://github.com/seu-usuario/lialean-server.git lialean_server

# 2. Configurar variáveis de ambiente
cd lialean_server/stacks
cp .env.example .env
nano .env  # Preencher TODAS as variáveis

# 3. Iniciar a stack
docker compose up -d
```

### Documentação Completa

📖 **[GUIA_COMPLETO.md](GUIA_COMPLETO.md)** - Guia passo a passo detalhado

---

## 📁 Estrutura do Projeto

```
lialean_server/
├── README.md                    # Este arquivo
├── GUIA_COMPLETO.md             # Guia definitivo de instalação
├── stacks/
│   ├── docker-compose.yml       # Orquestração de todos os serviços
│   └── .env.example             # Template de variáveis de ambiente
├── apps/
│   └── lialean-site/
│       ├── Dockerfile           # Build do site LiaLean
│       ├── .dockerignore        # Arquivos ignorados no build
│       └── [código-fonte]       # Código do site
├── scripts/
│   └── backup.sh                # Script de backup automático
└── docs/
    └── ARCHITECTURE.md          # Documentação da arquitetura
```

---

## 🌐 Domínios e Serviços

| Domínio | Serviço | Porta |
|---------|---------|-------|
| `lialean.cloud` | Site LiaLean | 443 |
| `n8n.vps.lialean.cloud` | N8N Main | 443 |
| `webhook.vps.lialean.cloud` | N8N Webhook | 443 |
| `portainer.vps.lialean.cloud` | Portainer | 443 |
| `traefik.vps.lialean.cloud` | Traefik Dashboard | 443 |
| `wp.vps.lialean.cloud` | WordPress | 443 |

Todos os serviços usam **HTTPS** com certificados SSL automáticos via Let's Encrypt.

---

## 🔧 Comandos Úteis

### Ver status de todos os containers
```bash
cd /opt/lialean_server/stacks
docker compose ps
```

### Ver logs de um serviço
```bash
docker compose logs -f nome_do_servico
```

### Reiniciar um serviço
```bash
docker compose restart nome_do_servico
```

### Atualizar a stack
```bash
docker compose pull
docker compose up -d
```

### Backup dos dados
```bash
cd /opt
tar -czvf backup_$(date +%F).tar.gz lialean_server/data
```

---

## 🛠️ Troubleshooting

### Certificado SSL não emitido

1. Verificar DNS:
   ```bash
   dig +short seu_dominio.com
   ```

2. Ver logs do Traefik:
   ```bash
   docker logs traefik | grep -i "certificate"
   ```

3. Limpar e reiniciar:
   ```bash
   docker compose stop traefik
   rm /opt/lialean_server/data/traefik/acme.json
   touch /opt/lialean_server/data/traefik/acme.json
   chmod 600 /opt/lialean_server/data/traefik/acme.json
   docker compose up -d traefik
   ```

### Container reiniciando

```bash
docker logs nome_do_container --tail 100
```

Consulte o **[GUIA_COMPLETO.md](GUIA_COMPLETO.md)** seção 12 (Troubleshooting) para mais detalhes.

---

## 📊 Requisitos de Sistema

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disco | 40 GB | 100 GB |
| Rede | 100 Mbps | 1 Gbps |

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork este repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Suporte

- **Site**: https://lialean.cloud
- **Email**: contato@lialean.com
- **GitHub Issues**: https://github.com/seu-usuario/lialean-server/issues

---

## 🙏 Agradecimentos

- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/)
- [N8N](https://n8n.io/)
- [Let's Encrypt](https://letsencrypt.org/)

---

**Desenvolvido com ❤️ pela equipe LiaLean**

