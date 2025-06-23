#!/bin/bash

# 🧹 Script de Cleanup VPC Default
# Remove recursos da VPC default da conta AWS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[ATENÇÃO]${NC} $1"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    echo "🧹 Cleanup VPC Default"
    echo "======================"
    echo
    
    # Verifica se AWS CLI está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        error "❌ AWS CLI não configurado. Configure suas credenciais."
    fi
    
    success "✅ AWS CLI configurado"
    
    # Obtém informações da conta
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    REGION=$(aws configure get region || echo "us-east-1")
    
    log "📊 Conta: $ACCOUNT_ID"
    log "🌍 Região: $REGION"
    
    # =============================================================================
    # VERIFICAR VPC DEFAULT
    # =============================================================================
    
    log "🔍 Verificando VPC default..."
    
    # Obtém a VPC default
    DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=is-default,Values=true" \
        --query 'Vpcs[0].VpcId' \
        --output text)
    
    if [ "$DEFAULT_VPC_ID" = "None" ] || [ -z "$DEFAULT_VPC_ID" ]; then
        warning "❌ Nenhuma VPC default encontrada."
        exit 0
    fi
    
    log "📍 VPC Default encontrada: $DEFAULT_VPC_ID"
    
    # =============================================================================
    # LISTAR RECURSOS
    # =============================================================================
    
    log "📋 Listando recursos na VPC default..."
    
    EC2_INSTANCES=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text)
    RDS_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?DBSubnetGroup.VpcId==\`$DEFAULT_VPC_ID\`].DBInstanceIdentifier" --output text 2>/dev/null || echo "")
    ELB_V1=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId==\`$DEFAULT_VPC_ID\`].LoadBalancerName" --output text 2>/dev/null || echo "")
    ELB_V2=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId==\`$DEFAULT_VPC_ID\`].LoadBalancerArn" --output text 2>/dev/null || echo "")
    SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[].GroupId' --output text)
    IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$DEFAULT_VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" --query 'Subnets[].SubnetId' --output text)
    ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" --query 'RouteTables[?Associations[?Main!=`true`]].RouteTableId' --output text)
    NETWORK_ACLS=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" --query 'NetworkAcls[?IsDefault!=`true`].NetworkAclId' --output text)

    # =============================================================================
    # MOSTRAR RESUMO
    # =============================================================================
    
    echo
    log "📊 Recursos encontrados na VPC Default:"
    
    [[ -n "$EC2_INSTANCES" ]] && log "   🖥️  EC2 Instances: $EC2_INSTANCES" || log "   ✅ Nenhuma EC2 Instance"
    [[ -n "$RDS_INSTANCES" ]] && log "   🗄️  RDS Instances: $RDS_INSTANCES" || log "   ✅ Nenhuma RDS Instance"
    [[ -n "$ELB_V1" ]] && log "   ⚖️  ELB V1: $ELB_V1" || log "   ✅ Nenhum ELB V1"
    [[ -n "$ELB_V2" ]] && log "   ⚖️  ELB V2: $ELB_V2" || log "   ✅ Nenhum ELB V2"
    [[ -n "$SUBNETS" ]] && log "   🌐 Subnets: $SUBNETS" || log "   ✅ Nenhuma Subnet"
    [[ -n "$ROUTE_TABLES" ]] && log "   🗺️  Route Tables (custom): $ROUTE_TABLES" || log "   ✅ Nenhuma Route Table customizada"
    [[ -n "$NETWORK_ACLS" ]] && log "   🛡️  Network ACLs (custom): $NETWORK_ACLS" || log "   ✅ Nenhuma Network ACL customizada"
    [[ -n "$SECURITY_GROUPS" ]] && log "   🔒 Security Groups (custom): $SECURITY_GROUPS" || log "   ✅ Nenhum Security Group customizado"
    [[ -n "$IGW" && "$IGW" != "None" ]] && log "   🌐 Internet Gateway: $IGW" || log "   ✅ Nenhum Internet Gateway"
    
    # =============================================================================
    # CONFIRMAÇÃO
    # =============================================================================
    
    echo
    warning "⚠️  ATENÇÃO: Esta operação irá remover recursos da VPC default!"
    warning "⚠️  Certifique-se de que não há recursos importantes."
    
    echo
    read -p "🤔 Continuar com o cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "❌ Cleanup cancelado"
        exit 1
    fi
    
    # =============================================================================
    # EXECUTAR CLEANUP
    # =============================================================================
    
    log "🧹 Iniciando cleanup..."
    
    if [ -n "$EC2_INSTANCES" ]; then
        log "🗑️  Removendo EC2 Instances..."
        aws ec2 terminate-instances --instance-ids $EC2_INSTANCES >/dev/null
    fi
    
    if [ -n "$RDS_INSTANCES" ]; then
        log "🗑️  Removendo RDS Instances..."
        for rds in $RDS_INSTANCES; do
            aws rds delete-db-instance --db-instance-identifier "$rds" --skip-final-snapshot --delete-automated-backups >/dev/null
        done
    fi
    
    if [ -n "$ELB_V1" ]; then
        log "🗑️  Removendo ELB V1..."
        for elb in $ELB_V1; do aws elb delete-load-balancer --load-balancer-name "$elb" >/dev/null; done
    fi
    
    if [ -n "$ELB_V2" ]; then
        log "🗑️  Removendo ELB V2..."
        for elb in $ELB_V2; do aws elbv2 delete-load-balancer --load-balancer-arn "$elb" >/dev/null; done
    fi
    
    if [ -n "$IGW" ] && [ "$IGW" != "None" ]; then
        log "🗑️  Removendo Internet Gateway..."
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$DEFAULT_VPC_ID" >/dev/null 2>&1 || true
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW" >/dev/null 2>&1 || true
    fi
    
    if [ -n "$SUBNETS" ]; then
        log "🗑️  Removendo Subnets..."
        for subnet in $SUBNETS; do aws ec2 delete-subnet --subnet-id "$subnet" >/dev/null 2>&1 || true; done
    fi
    
    if [ -n "$ROUTE_TABLES" ]; then
        log "🗑️  Removendo Route Tables..."
        for rt in $ROUTE_TABLES; do aws ec2 delete-route-table --route-table-id "$rt" >/dev/null 2>&1 || true; done
    fi
    
    if [ -n "$NETWORK_ACLS" ]; then
        log "🗑️  Removendo Network ACLs..."
        for acl in $NETWORK_ACLS; do aws ec2 delete-network-acl --network-acl-id "$acl" >/dev/null 2>&1 || true; done
    fi
    
    if [ -n "$SECURITY_GROUPS" ]; then
        log "🗑️  Removendo Security Groups..."
        for sg in $SECURITY_GROUPS; do aws ec2 delete-security-group --group-id "$sg" >/dev/null 2>&1 || true; done
    fi
    
    # =============================================================================
    # REMOVER VPC DEFAULT
    # =============================================================================
    
    log "🗑️  Removendo VPC Default..."
    
    # Aguardar para garantir que recursos foram removidos
    log "⏳ Aguardando 15 segundos para a propagação da remoção de recursos..."
    sleep 15
    
    # Tentar remover a VPC default
    if aws ec2 delete-vpc --vpc-id "$DEFAULT_VPC_ID" >/dev/null 2>&1; then
        success "✅ VPC Default $DEFAULT_VPC_ID removida com sucesso!"
    else
        warning "⚠️  Não foi possível remover a VPC Default automaticamente."
        warning "💡  Ainda podem existir dependências. Verifique o console da AWS."
        warning "💡  Tente rodar o script novamente ou execute: aws ec2 delete-vpc --vpc-id $DEFAULT_VPC_ID"
    fi
    
    echo
    success "🎉 Cleanup concluído!"
}

# Executa a função principal
main "$@" 