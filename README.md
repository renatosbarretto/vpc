# AWS Hub and Spoke Architecture with Terraform

Este projeto implementa uma arquitetura de rede Hub and Spoke na AWS usando Terraform, com Transit Gateway para conectividade entre VPCs.

## 🏗️ Arquitetura

```
                    ┌─────────────────┐
                    │   Internet      │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │  Internet       │
                    │  Gateway        │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   Hub VPC       │
                    │  (10.0.0.0/16)  │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Public      │ │
                    │ │ Subnets     │ │
                    │ └─────────────┘ │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Private     │ │
                    │ │ Subnets     │ │
                    │ │ + NAT GW    │ │
                    │ └─────────────┘ │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │  Transit        │
                    │  Gateway        │
                    └─────────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼──────┐    ┌─────────▼────────┐    ┌──────▼──────┐
│  Dev Spoke   │    │ Staging Spoke    │    │ Prod Spoke  │
│(10.1.0.0/16) │    │ (10.2.0.0/16)   │    │(10.3.0.0/16)│
│              │    │                  │    │              │
│ ┌──────────┐ │    │ ┌──────────────┐ │    │ ┌──────────┐ │
│ │ Private  │ │    │ │ Private      │ │    │ │ Private  │ │
│ │ Subnets  │ │    │ │ Subnets      │ │    │ │ Subnets  │ │
│ └──────────┘ │    │ └──────────────┘ │    │ └──────────┘ │
└──────────────┘    └──────────────────┘    └──────────────┘
```

## ✨ Funcionalidades

### 🚀 Resolução de Problemas Críticos
- **Ordem de criação correta**: Dependências explícitas resolvem o erro `InvalidTransitGatewayID.NotFound`
- **Subnets dinâmicas**: Geração automática usando `cidrsubnet()` para evitar conflitos
- **DNS Support**: Transit Gateway habilitado para resolução de domínios internos da AWS

### 🔧 Arquitetura Modular
- **Módulo Hub**: VPC central com Transit Gateway, NAT Gateways e conectividade externa
- **Módulo Spoke**: VPCs periféricas conectadas ao Hub via Transit Gateway
- **Reutilização**: Módulos parametrizados para diferentes ambientes

### 🌐 Conectividade Completa
- **Hub → Spokes**: Rotas automáticas para todos os spokes
- **Spokes → Internet**: Tráfego externo via Hub e NAT Gateways
- **Spokes → Hub**: Comunicação bidirecional entre VPCs
- **DNS interno**: Resolução de serviços AWS via Transit Gateway

### 🏷️ Tags e Boas Práticas
- **Tags consistentes**: Name, Project, Environment, ManagedBy
- **Tags adicionais**: Owner, CostCenter, Application
- **Validações**: Verificação de parâmetros obrigatórios

## 📁 Estrutura do Projeto

```
├── main.tf                    # Configuração principal
├── variables.tf               # Variáveis do projeto
├── outputs.tf                 # Outputs do projeto
├── backend.tf                 # Configuração do backend S3
├── modules/
│   ├── hub/
│   │   ├── main.tf           # Módulo Hub
│   │   ├── variables.tf      # Variáveis do Hub
│   │   ├── outputs.tf        # Outputs do Hub
│   │   └── README.md         # Documentação do Hub
│   └── spoke/
│       ├── main.tf           # Módulo Spoke
│       ├── variables.tf      # Variáveis do Spoke
│       ├── outputs.tf        # Outputs do Spoke
│       └── README.md         # Documentação do Spoke
├── examples/
│   └── multi-spoke.tf        # Exemplo com múltiplos spokes
└── README.md                 # Este arquivo
```

## 🚀 Uso Rápido

### 1. Configuração Inicial

```bash
# Inicializar o Terraform
terraform init

# Verificar o plano
terraform plan

# Aplicar a configuração
terraform apply
```

### 2. Configuração Básica

```hcl
# main.tf
module "hub" {
  source = "./modules/hub"

  vpc_cidr      = "10.0.0.0/16"
  environment   = "dev"
  project       = "my-project"
  number_of_azs = 2
}

module "dev_spoke" {
  source = "./modules/spoke"

  vpc_cidr      = "10.1.0.0/16"
  environment   = "dev"
  spoke_name    = "dev"
  transit_gateway_id = module.hub.transit_gateway_id
}
```

### 3. Múltiplos Spokes

```hcl
locals {
  spokes = {
    dev = { vpc_cidr = "10.1.0.0/16", name = "dev" }
    staging = { vpc_cidr = "10.2.0.0/16", name = "staging" }
    prod = { vpc_cidr = "10.3.0.0/16", name = "prod" }
  }
}

module "spokes" {
  source = "./modules/spoke"
  
  for_each = local.spokes

  vpc_cidr = each.value.vpc_cidr
  environment = "prod"
  spoke_name = each.value.name
  transit_gateway_id = module.hub.transit_gateway_id
}
```

## 📋 Pré-requisitos

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **AWS CLI**: Configurado com credenciais válidas
- **Backend S3**: Bucket e tabela DynamoDB para estado remoto

## 🔧 Configuração do Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-684120556098"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## 📊 Outputs Principais

```bash
# Informações do Hub
hub_vpc_id = "vpc-xxxxxxxxx"
transit_gateway_id = "tgw-xxxxxxxxx"
hub_public_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]

# Informações dos Spokes
spokes = {
  dev = {
    vpc_id = "vpc-xxxxxxxxx"
    vpc_cidr = "10.1.0.0/16"
    private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  }
}

# Resumo da arquitetura
network_summary = {
  hub = {
    vpc_cidr = "10.0.0.0/16"
    public_subnets = 2
    private_subnets = 2
    nat_gateways = 2
  }
  spokes = {
    count = 1
    names = ["dev"]
  }
  transit_gateway = {
    id = "tgw-xxxxxxxxx"
    attachments = 2
  }
}
```

## 🔍 Troubleshooting

### Erro: InvalidTransitGatewayID.NotFound
**Causa**: Ordem incorreta de criação dos recursos
**Solução**: ✅ **RESOLVIDO** - Dependências explícitas nos módulos

### Erro: AddressLimitExceeded
**Causa**: Muitas subnets criadas simultaneamente
**Solução**: ✅ **RESOLVIDO** - Subnets dinâmicas com `cidrsubnet()`

### Erro: Duplicate CIDR blocks
**Causa**: CIDRs conflitantes entre VPCs
**Solução**: ✅ **RESOLVIDO** - Validação e geração automática

## 🧪 Testes

### Conectividade Hub → Spoke
```bash
# Testar conectividade do Hub para o Spoke
ping 10.1.1.10  # IP de uma instância no Spoke
```

### Conectividade Spoke → Internet
```bash
# Testar saída de internet do Spoke
curl ifconfig.me  # Deve retornar IP do NAT Gateway do Hub
```

### DNS Resolution
```bash
# Testar resolução de domínios internos da AWS
nslookup rds.amazonaws.com  # Deve resolver via Transit Gateway
```

## 📈 Próximos Passos

- [ ] Adicionar Security Groups
- [ ] Implementar VPC Endpoints
- [ ] Configurar CloudWatch Logs
- [ ] Adicionar monitoramento de conectividade
- [ ] Implementar backup de configurações
- [ ] Criar scripts de validação

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte

Para dúvidas ou problemas:
- Abra uma issue no GitHub
- Consulte a documentação dos módulos
- Verifique os exemplos na pasta `examples/` 