# 🌐 VPC Hub - AWS Terraform

Projeto simples para estudos de VPC Hub na AWS usando Terraform.

## 📋 Arquitetura

```
                    ┌─────────────────┐
                    │   INTERNET      │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   VPC HUB       │
                    │ 10.0.0.0/16     │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │Public Subnet│ │ ← us-east-1a
                    │ │10.0.1.0/24  │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Public Subnet│ │ ← us-east-1b
                    │ │10.0.2.0/24  │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Public Subnet│ │ ← us-east-1c
                    │ │10.0.3.0/24  │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Public Subnet│ │ ← us-east-1d
                    │ │10.0.4.0/24  │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │Private Subnet│ │ ← us-east-1a
                    │ │10.0.10.0/24 │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Private Subnet│ │ ← us-east-1b
                    │ │10.0.11.0/24 │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Private Subnet│ │ ← us-east-1c
                    │ │10.0.12.0/24 │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │Private Subnet│ │ ← us-east-1d
                    │ │10.0.13.0/24 │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │Transit Gateway│ │
                    │ └─────────────┘ │
                    └─────────────────┘
```

## 🏗️ Componentes

### VPC Hub (Central)
- **CIDR**: `10.0.0.0/16`
- **Subnets Públicas**: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`, `10.0.4.0/24`
- **Subnets Privadas**: `10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24`
- **Availability Zones**: 4 AZs (us-east-1a, us-east-1b, us-east-1c, us-east-1d)
- **Internet Gateway**: Para acesso à internet
- **NAT Gateway**: 4 NAT Gateways (um por AZ)
- **Transit Gateway**: Para futuras conexões com VPCs Spoke

## 🚀 Como Usar

### Pré-requisitos
- Terraform >= 1.0
- AWS CLI configurado
- Credenciais AWS válidas

### Deploy
```bash
# Dar permissão de execução
chmod +x scripts_vpc/deploy.sh

# Executar deploy
./scripts_vpc/deploy.sh
```

O script irá:
1. ✅ Verificar dependências
2. 🚀 Deployar VPC Hub

### Deploy Manual
```bash
cd vpc/hub
terraform init
terraform plan
terraform apply
```

## 📁 Estrutura do Projeto

```
Blueprint_EKS/
├── scripts_vpc/           # Scripts de automação
│   ├── deploy.sh          # Script de deploy
│   ├── destroy.sh         # Script de destroy
│   ├── cleanup_default_vpc.sh  # Script de cleanup VPC default
│   └── remove_vpc.sh      # Remove VPC específica
├── README.md              # Este arquivo
└── vpc/
    └── hub/               # VPC Hub (central)
        ├── main.tf
        └── outputs.tf
```

## 🔧 Scripts Disponíveis

### 🚀 `deploy.sh`
- Deploya a VPC Hub com todas as configurações.
- Pede confirmação antes de aplicar.

### 🗑️ `destroy.sh`
- Remove toda a infraestrutura da VPC Hub.
- Pede confirmação antes de destruir.

### 🧹 `cleanup_default_vpc.sh`
- **Remove a VPC default** da conta AWS.
- Identifica e remove recursos associados (EC2, RDS, ELB, etc.).
- **⚠️ ATENÇÃO**: Use com cuidado, remove recursos permanentemente.

### 🗑️ `remove_vpc.sh`
- **Remove uma VPC específica** (não-default) da conta.
- Mostra um **menu interativo** para escolher a VPC.
- Verifica e remove recursos associados antes de deletar a VPC.

## 🔧 Características

- ✅ **Simples**: Fácil de entender e modificar
- ✅ **Completa**: Subnets públicas e privadas em 4 AZs
- ✅ **Alta Disponibilidade**: Distribuído em múltiplas AZs
- ✅ **Preparada**: Transit Gateway para futuras expansões
- ✅ **Segura**: NAT Gateway para subnets privadas
- ✅ **Organizada**: Scripts separados em pasta própria
- ✅ **Limpa**: Scripts para remover VPCs indesejadas

## 🎯 Próximos Passos

1. **VPCs Spoke**: Adicionar VPCs Dev, Staging, Prod
2. **EKS Clusters**: Adicionar clusters Kubernetes
3. **GitHub Actions**: Automatizar deploy via CI/CD
4. **Monitoring**: CloudWatch e logs
5. **Security**: Security Groups e NACLs

## 💡 Conceitos Aprendidos

- **VPC**: Virtual Private Cloud
- **Subnets**: Divisão da rede VPC
- **Availability Zones**: Redundância geográfica
- **Internet Gateway**: Acesso à internet
- **NAT Gateway**: Internet para subnets privadas
- **Transit Gateway**: Conectividade entre VPCs
- **Route Tables**: Controle de roteamento
- **Terraform**: Infraestrutura como código

## 🧹 Cleanup

### Remover VPC Hub
```bash
# Usando script
./scripts_vpc/destroy.sh
```

### Limpar VPC Default (Opcional)
```bash
# Remove VPC default e recursos associados
./scripts_vpc/cleanup_default_vpc.sh
```

### Remover uma VPC Específica
```bash
# Abre menu para selecionar e remover uma VPC
./scripts_vpc/remove_vpc.sh
```

---

**Nota**: Este é um projeto para estudos. Em produção, considere adicionar mais segurança, monitoring e backup. 