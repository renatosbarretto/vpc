# Spoke Module

Este módulo cria uma VPC Spoke conectada ao Hub via Transit Gateway na arquitetura Hub and Spoke da AWS.

## Funcionalidades

- **VPC Spoke** com subnets privadas
- **Transit Gateway Attachment** para conectividade com o Hub
- **Subnets dinâmicas** geradas automaticamente usando `cidrsubnet()`
- **DNS Support** habilitado no Transit Gateway Attachment
- **Tags consistentes** em todos os recursos
- **Dependências corretas** para evitar problemas de ordem de criação

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|-------------|
| vpc_cidr | CIDR block da VPC Spoke | `string` | n/a | sim |
| environment | Ambiente (dev, staging, prod, test) | `string` | n/a | sim |
| spoke_name | Nome do spoke (dev, staging, prod, app1, etc.) | `string` | n/a | sim |
| project | Nome do projeto | `string` | `"vpc-hub-spoke"` | não |
| number_of_azs | Número de Availability Zones | `number` | `2` | não |
| transit_gateway_id | ID do Transit Gateway do Hub | `string` | n/a | sim |
| transit_gateway_attachment_dependencies | Dependências para o attachment | `any` | `[]` | não |
| common_tags | Tags comuns para todos os recursos | `map(string)` | `{ManagedBy = "terraform"}` | não |
| additional_tags | Tags adicionais | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| vpc_id | ID da VPC Spoke |
| vpc_cidr | CIDR block da VPC Spoke |
| private_subnet_ids | IDs das subnets privadas |
| private_subnet_cidrs | CIDR blocks das subnets privadas |
| transit_gateway_attachment_id | ID do Transit Gateway Attachment |
| private_route_table_id | ID da Route Table privada |
| availability_zones | Lista de Availability Zones utilizadas |

## Exemplo de Uso

```hcl
module "dev_spoke" {
  source = "./modules/spoke"

  vpc_cidr      = "10.1.0.0/16"
  environment   = "dev"
  spoke_name    = "dev"
  project       = "my-project"
  number_of_azs = 2
  
  transit_gateway_id = module.hub.transit_gateway_id
  transit_gateway_attachment_dependencies = [module.hub.transit_gateway_attachment_id]
  
  common_tags = {
    Environment = "dev"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Recursos Criados

- 1 VPC Spoke
- 2-4 subnets privadas (conforme `number_of_azs`)
- 1 Transit Gateway VPC Attachment
- 1 Route Table privada
- Associações de Route Tables

## Notas Importantes

- **Subnets apenas privadas**: Spokes não possuem subnets públicas por padrão
- **Conectividade via Hub**: Todo tráfego externo passa pelo Hub via Transit Gateway
- **DNS Support**: Habilitado para resolução de domínios internos da AWS
- **Dependências**: O módulo aguarda a criação do attachment do Hub antes de criar o próprio attachment 