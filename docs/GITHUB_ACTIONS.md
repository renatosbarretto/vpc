# GitHub Actions para Infraestrutura Terraform

Este documento descreve os workflows do GitHub Actions configurados para automatizar o deploy e gerenciamento da infraestrutura Terraform.

## 📋 Workflows Disponíveis

### 1. Terraform Infrastructure (`terraform.yml`)

**Trigger:** Push para `main`, Pull Requests, ou manual via `workflow_dispatch`

**Funcionalidades:**
- ✅ Validação e formatação do código Terraform
- ✅ Inicialização e validação
- ✅ Planejamento automático em Pull Requests
- ✅ Aplicação automática em push para `main`
- ✅ Destruição manual via workflow dispatch

**Como usar:**
1. **Automático:** Push para `main` aplica automaticamente
2. **Pull Request:** Cria comentário com o plano de mudanças
3. **Manual:** Vá em Actions → Terraform Infrastructure → Run workflow

### 2. Security and Quality Checks (`security-scan.yml`)

**Trigger:** Push para `main` ou Pull Requests

**Funcionalidades:**
- 🔍 **Checkov:** Análise de segurança do código Terraform
- 🛠️ **TFLint:** Verificação de qualidade e boas práticas
- 📚 **Terraform Docs:** Geração automática de documentação
- 📊 **Relatórios:** Comentários automáticos em Pull Requests

### 3. Deploy to Environments (`deploy-environments.yml`)

**Trigger:** Manual via `workflow_dispatch`

**Funcionalidades:**
- 🌍 Deploy para múltiplos ambientes (dev, staging, prod)
- 🔒 Proteção por ambiente com aprovações
- ⚡ Ações: plan, apply, destroy

## 🔐 Configuração de Secrets

Configure os seguintes secrets no seu repositório GitHub:

```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

### Como configurar:

1. Vá para seu repositório no GitHub
2. Settings → Secrets and variables → Actions
3. Adicione os secrets acima

## 🚀 Como Usar

### Deploy Automático

1. Faça push para a branch `main`
2. O workflow executa automaticamente:
   - Validação de código
   - Aplicação da infraestrutura

### Deploy Manual

1. Vá para Actions → Terraform Infrastructure
2. Clique em "Run workflow"
3. Escolha a ação:
   - `plan`: Apenas planeja as mudanças
   - `apply`: Aplica as mudanças
   - `destroy`: Destrói a infraestrutura

### Pull Request

1. Crie uma Pull Request
2. Os workflows executam automaticamente:
   - Validação de segurança
   - Análise de qualidade
   - Planejamento das mudanças
3. Comentários são adicionados automaticamente

## 📊 Monitoramento

### Status dos Workflows

- ✅ **Verde:** Sucesso
- ❌ **Vermelho:** Falha
- 🟡 **Amarelo:** Em execução

### Logs e Debugging

1. Vá para Actions no GitHub
2. Clique no workflow desejado
3. Clique no job específico
4. Expanda os steps para ver logs detalhados

## 🔧 Configurações Avançadas

### Personalizar Regras de Segurança

Edite `.checkov.yml` para:
- Pular verificações específicas
- Excluir diretórios
- Configurar saída

### Personalizar TFLint

Edite `.tflint.hcl` para:
- Habilitar/desabilitar regras
- Configurar plugins
- Definir convenções de nomenclatura

### Adicionar Novos Ambientes

1. Crie diretório em `environments/`
2. Configure variáveis específicas
3. Adicione ao workflow `deploy-environments.yml`

## 🛡️ Boas Práticas

### Segurança

- ✅ Nunca commite credenciais
- ✅ Use secrets do GitHub
- ✅ Revise Pull Requests
- ✅ Teste em ambiente de desenvolvimento

### Qualidade

- ✅ Execute `terraform fmt` antes do commit
- ✅ Valide código com `terraform validate`
- ✅ Use TFLint para boas práticas
- ✅ Documente mudanças

### Operação

- ✅ Sempre faça `plan` antes de `apply`
- ✅ Use branches para mudanças
- ✅ Monitore logs de execução
- ✅ Tenha rollback plan

## 🆘 Troubleshooting

### Problemas Comuns

**Workflow falha na validação:**
```bash
terraform fmt
terraform validate
```

**Erro de credenciais AWS:**
- Verifique se os secrets estão configurados
- Confirme se as credenciais têm permissões adequadas

**Timeout no apply:**
- Verifique se há recursos que demoram para criar
- Considere aumentar o timeout do job

### Logs Úteis

```bash
# Verificar estado do Terraform
terraform state list

# Verificar outputs
terraform output

# Verificar plan
terraform plan
```

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs do workflow
2. Consulte a documentação do Terraform
3. Abra uma issue no repositório 