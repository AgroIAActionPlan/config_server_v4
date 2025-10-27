# Contribuindo para o LiaLean Server

Obrigado por considerar contribuir para o projeto LiaLean Server! Este documento fornece diretrizes para contribuições.

## Como Contribuir

### 1. Reportar Bugs

Se você encontrou um bug, por favor:

1. Verifique se o bug já não foi reportado nas [Issues](https://github.com/AgroIAActionPlan/config_server_v4/issues)
2. Se não existir, crie uma nova issue com:
   - Título descritivo
   - Descrição detalhada do problema
   - Passos para reproduzir
   - Comportamento esperado vs. comportamento atual
   - Logs relevantes (se aplicável)
   - Ambiente (Ubuntu version, Docker version, etc.)

### 2. Sugerir Melhorias

Para sugerir melhorias:

1. Abra uma issue com o label `enhancement`
2. Descreva claramente a melhoria proposta
3. Explique por que essa melhoria seria útil
4. Se possível, forneça exemplos de uso

### 3. Contribuir com Código

#### Fork e Clone

```bash
# Fork o repositório no GitHub
# Clone seu fork
git clone https://github.com/SEU_USUARIO/config_server_v4.git
cd config_server_v4

# Adicione o repositório original como upstream
git remote add upstream https://github.com/AgroIAActionPlan/config_server_v4.git
```

#### Criar uma Branch

```bash
# Crie uma branch para sua feature ou correção
git checkout -b feature/nome-da-feature
# ou
git checkout -b fix/nome-do-bug
```

#### Fazer Mudanças

1. Faça suas mudanças no código
2. Teste localmente
3. Certifique-se de que a documentação está atualizada
4. Siga as convenções de código do projeto

#### Commit

Use mensagens de commit semânticas:

```bash
# Formato
tipo(escopo): descrição curta

# Exemplos
feat(docker): adiciona suporte para Redis Sentinel
fix(traefik): corrige configuração de SSL
docs(readme): atualiza instruções de instalação
chore(deps): atualiza dependências do Docker
```

**Tipos de commit**:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Mudanças na documentação
- `style`: Formatação, ponto e vírgula, etc.
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Manutenção, atualização de dependências

#### Push e Pull Request

```bash
# Push para seu fork
git push origin feature/nome-da-feature

# Abra um Pull Request no GitHub
```

No Pull Request, inclua:
- Descrição clara das mudanças
- Referência a issues relacionadas (ex: `Closes #123`)
- Screenshots (se aplicável)
- Checklist de testes realizados

### 4. Revisar Pull Requests

Contribuições de revisão também são bem-vindas! Ao revisar:

- Seja respeitoso e construtivo
- Teste as mudanças localmente
- Verifique se a documentação está atualizada
- Comente sobre possíveis melhorias

## Convenções de Código

### Docker Compose

- Use indentação de 2 espaços
- Ordene serviços alfabeticamente
- Comente configurações complexas
- Use variáveis de ambiente para valores sensíveis

### Documentação

- Use Markdown para documentação
- Mantenha linhas com no máximo 120 caracteres
- Use títulos descritivos
- Inclua exemplos práticos
- Atualize o índice quando adicionar seções

### Scripts

- Use `#!/bin/bash` como shebang
- Adicione comentários explicativos
- Use `set -e` para parar em erros
- Valide entradas do usuário

## Processo de Revisão

1. Mantenedores revisarão seu PR
2. Podem solicitar mudanças
3. Após aprovação, o PR será merged
4. Seu nome será adicionado aos contribuidores

## Código de Conduta

- Seja respeitoso com outros contribuidores
- Aceite críticas construtivas
- Foque no que é melhor para o projeto
- Seja paciente com novos contribuidores

## Dúvidas?

Se tiver dúvidas, abra uma issue com o label `question` ou entre em contato:

- Email: contato@lialean.com
- Site: https://lialean.cloud

---

**Obrigado por contribuir!** 🚀

