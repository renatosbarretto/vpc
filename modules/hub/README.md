# Hub Module

Este módulo cria uma VPC Hub central com Transit Gateway para arquitetura Hub and Spoke na AWS.

## Funcionalidades

- **VPC Hub** com subnets públicas e privadas
- **Internet Gateway** para conectividade externa
- **NAT Gateways** para saída de internet das subnets privadas
- **Transit Gateway** para conectividade entre VPCs
- **Subnets dinâmicas** geradas automaticamente usando `cidrsubnet()`
- **DNS Support** habilitado no Transit Gateway
- **Tags consistentes** em todos os recursos

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|-------------|
| vpc_cidr | CIDR block da VPC Hub | `string` | `"10.0.0.0/16"` | não |
| environment | Ambiente (dev, staging, prod, test) | `string` | n/a | sim |
| project | Nome do projeto | `string` | `"vpc-hub-spoke"` | não |
| number_of_azs | Número de Availability Zones | `number` | `2` | não |
| common_tags | Tags comuns para todos os recursos | `map(string)` | `{ManagedBy = "terraform"}` | não |
| additional_tags | Tags adicionais | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| vpc_id | ID da VPC Hub |
| vpc_cidr | CIDR block da VPC Hub |
| public_subnet_ids | IDs das subnets públicas |
| private_subnet_ids | IDs das subnets privadas |
| transit_gateway_id | ID do Transit Gateway |
| transit_gateway_attachment_id | ID do attachment do TGW para o Hub |
| internet_gateway_id | ID do Internet Gateway |
| nat_gateway_ids | IDs dos NAT Gateways |

## Exemplo de Uso

```hcl
module "hub" {
  source = "./modules/hub"

  vpc_cidr      = "10.0.0.0/16"
  environment   = "dev"
  project       = "my-project"
  number_of_azs = 2
  
  common_tags = {
    Environment = "dev"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Recursos Criados

- 1 VPC
- 2-4 subnets públicas (conforme `number_of_azs`)
- 2-4 subnets privadas (conforme `number_of_azs`)
- 1 Internet Gateway
- 2-4 NAT Gateways (conforme `number_of_azs`)
- 2-4 Elastic IPs (conforme `number_of_azs`)
- 1 Transit Gateway
- 1 Transit Gateway VPC Attachment
- 1 Route Table pública
- 2-4 Route Tables privadas (conforme `number_of_azs`)
- Associações de Route Tables 