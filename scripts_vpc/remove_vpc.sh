#!/bin/bash

# 🗑️ Script para Remover VPC Específica
# Remove uma VPC específica da conta AWS com menu interativo

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
    echo "🗑️ Remover VPC Específica"
    echo "========================="
    echo
    
    # Verifica se AWS CLI está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        error "❌ AWS CLI não configurado. Configure suas credenciais."
        exit 1
    fi
    
    success "✅ AWS CLI configurado"
    
    # Obtém informações da conta
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    REGION=$(aws configure get region || echo "us-east-1")
    
    log "📊 Conta: $ACCOUNT_ID"
    log "🌍 Região: $REGION"
    
    # =============================================================================
    # SELECIONAR VPC
    # =============================================================================
    
    log "🔍 Listando VPCs disponíveis para seleção..."

    # Declare arrays to hold VPC info
    declare -a VPC_IDS
    declare -a VPC_IS_DEFAULT

    # Read VPCs into arrays and display a menu
    i=0
    echo
    printf "   %-4s %-22s %-18s %-25s %-10s\n" "#" "VPC ID" "CIDR Block" "Name Tag" "Is Default"
    echo "----------------------------------------------------------------------------------------------"

    # Use process substitution to read from aws cli output
    while IFS=$'\t' read -r vpc_id cidr name is_default; do
        VPC_IDS[i]="$vpc_id"
        VPC_IS_DEFAULT[i]="$is_default"
        # Handle case where name is None/null from the aws-cli query
        [ "$name" = "None" ] && name="N/A"
        
        printf "   [%d]  %-22s %-18s %-25s %-10s\n" "$((i+1))" "$vpc_id" "$cidr" "$name" "$is_default"
        i=$((i+1))
    done < <(aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0],IsDefault]' --output text)
    echo "----------------------------------------------------------------------------------------------"
    echo

    if [ $i -eq 0 ]; then
        success "✅ Nenhuma VPC encontrada na região $REGION."
        exit 0
    fi
    
    # =============================================================================
    # SOLICITAR ESCOLHA
    # =============================================================================

    VPC_ID=""
    while [ -z "$VPC_ID" ]; do
        read -p "Digite o número da VPC que deseja remover (ou 'q' para sair): " choice
        
        if [[ "$choice" == "q" ]]; then
            warning "❌ Operação cancelada pelo usuário."
            exit 1
        fi
        
        # Validate if input is a number
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            error "Entrada inválida. Por favor, digite um número da lista."
            continue
        fi
        
        # Validate if number is in range
        if [ "$choice" -lt 1 ] || [ "$choice" -gt ${#VPC_IDS[@]} ]; then
            error "Número fora do intervalo. Escolha um número entre 1 e ${#VPC_IDS[@]}."
            continue
        fi
        
        # Get selected VPC ID and its default status
        VPC_ID=${VPC_IDS[$((choice-1))]}
        IS_DEFAULT=${VPC_IS_DEFAULT[$((choice-1))]}
    done

    # Check if the selected VPC is a default VPC
    if [ "$IS_DEFAULT" = "True" ]; then
        warning "⚠️  A VPC selecionada ($VPC_ID) é uma VPC DEFAULT!"
        warning "💡  Para remover a VPC Default com segurança, use o script './cleanup_default_vpc.sh'."
        exit 1
    fi

    log "📍 VPC Selecionada: $VPC_ID"
    
    # =============================================================================
    # VERIFICAR RECURSOS
    # =============================================================================
    
    log "🔍 Verificando recursos na VPC..."
    
    # EC2 Instances
    EC2_INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' \
        --output text)
    
    # RDS Instances
    RDS_INSTANCES=$(aws rds describe-db-instances \
        --query "DBInstances[?DBSubnetGroup.VpcId==\`$VPC_ID\`].DBInstanceIdentifier" \
        --output text 2>/dev/null || echo "")
    
    # Load Balancers
    ELB_V1=$(aws elb describe-load-balancers \
        --query "LoadBalancerDescriptions[?VPCId==\`$VPC_ID\`].LoadBalancerName" \
        --output text 2>/dev/null || echo "")
    
    ELB_V2=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?VpcId==\`$VPC_ID\`].LoadBalancerArn" \
        --output text 2>/dev/null || echo "")
    
    # Security Groups (exceto default)
    SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" \
        --query 'SecurityGroups[].GroupId' \
        --output text)
    
    # Internet Gateways
    IGW=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text)
    
    # NAT Gateways
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways \
        --filter "Name=vpc-id,Values=$VPC_ID" \
        --query 'NatGateways[?State!=`deleted`].NatGatewayId' \
        --output text)
    
    # Subnets
    SUBNETS=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[].SubnetId' \
        --output text)
    
    # =============================================================================
    # MOSTRAR RESUMO
    # =============================================================================
    
    echo
    log "📊 Recursos encontrados na VPC $VPC_ID:"
    
    if [ -n "$EC2_INSTANCES" ]; then
        log "   🖥️  EC2 Instances: $EC2_INSTANCES"
    else
        log "   ✅ Nenhuma EC2 Instance"
    fi
    
    if [ -n "$RDS_INSTANCES" ]; then
        log "   🗄️  RDS Instances: $RDS_INSTANCES"
    else
        log "   ✅ Nenhuma RDS Instance"
    fi
    
    if [ -n "$ELB_V1" ]; then
        log "   ⚖️  ELB V1: $ELB_V1"
    else
        log "   ✅ Nenhum ELB V1"
    fi
    
    if [ -n "$ELB_V2" ]; then
        log "   ⚖️  ELB V2: $ELB_V2"
    else
        log "   ✅ Nenhum ELB V2"
    fi
    
    if [ -n "$NAT_GATEWAYS" ]; then
        log "   🌐 NAT Gateways: $NAT_GATEWAYS"
    else
        log "   ✅ Nenhum NAT Gateway"
    fi
    
    if [ -n "$SECURITY_GROUPS" ]; then
        log "   🔒 Security Groups: $SECURITY_GROUPS"
    else
        log "   ✅ Nenhum Security Group customizado"
    fi
    
    if [ -n "$IGW" ] && [ "$IGW" != "None" ]; then
        log "   🌐 Internet Gateway: $IGW"
    else
        log "   ✅ Nenhum Internet Gateway"
    fi
    
    if [ -n "$SUBNETS" ]; then
        log "   🌐 Subnets: $SUBNETS"
    else
        log "   ✅ Nenhuma Subnet"
    fi
    
    # =============================================================================
    # CONFIRMAÇÃO
    # =============================================================================
    
    echo
    warning "⚠️  ATENÇÃO: Esta operação irá remover a VPC $VPC_ID!"
    
    if [ -n "$EC2_INSTANCES$RDS_INSTANCES$ELB_V1$ELB_V2" ]; then
        warning "⚠️  Existem recursos ativos que serão removidos!"
    fi
    
    echo
    read -p "🤔 Continuar com a remoção? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "❌ Remoção cancelada"
        exit 1
    fi
    
    # =============================================================================
    # EXECUTAR REMOÇÃO
    # =============================================================================
    
    log "🗑️  Iniciando remoção da VPC $VPC_ID..."
    
    # Remover EC2 Instances
    if [ -n "$EC2_INSTANCES" ]; then
        log "🗑️  Removendo EC2 Instances..."
        for instance in $EC2_INSTANCES; do
            aws ec2 terminate-instances --instance-ids "$instance" >/dev/null
            log "   ✅ Instance $instance terminada"
        done
    fi
    
    # Remover RDS Instances
    if [ -n "$RDS_INSTANCES" ]; then
        log "🗑️  Removendo RDS Instances..."
        for rds in $RDS_INSTANCES; do
            aws rds delete-db-instance \
                --db-instance-identifier "$rds" \
                --skip-final-snapshot \
                --delete-automated-backups >/dev/null
            log "   ✅ RDS Instance $rds removida"
        done
    fi
    
    # Remover ELB V1
    if [ -n "$ELB_V1" ]; then
        log "🗑️  Removendo ELB V1..."
        for elb in $ELB_V1; do
            aws elb delete-load-balancer --load-balancer-name "$elb" >/dev/null
            log "   ✅ ELB V1 $elb removido"
        done
    fi
    
    # Remover ELB V2
    if [ -n "$ELB_V2" ]; then
        log "🗑️  Removendo ELB V2..."
        for elb in $ELB_V2; do
            aws elbv2 delete-load-balancer --load-balancer-arn "$elb" >/dev/null
            log "   ✅ ELB V2 $elb removido"
        done
    fi
    
    # Remover NAT Gateways
    if [ -n "$NAT_GATEWAYS" ]; then
        log "🗑️  Removendo NAT Gateways..."
        for nat in $NAT_GATEWAYS; do
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat" >/dev/null
            log "   ✅ NAT Gateway $nat removido"
        done
    fi
    
    # Remover Security Groups
    if [ -n "$SECURITY_GROUPS" ]; then
        log "🗑️  Removendo Security Groups..."
        for sg in $SECURITY_GROUPS; do
            aws ec2 delete-security-group --group-id "$sg" >/dev/null 2>&1 || true
            log "   ✅ Security Group $sg removido"
        done
    fi
    
    # Desanexar e remover Internet Gateway
    if [ -n "$IGW" ] && [ "$IGW" != "None" ]; then
        log "🗑️  Removendo Internet Gateway..."
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID" >/dev/null 2>&1 || true
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW" >/dev/null 2>&1 || true
        log "   ✅ Internet Gateway $IGW removido"
    fi
    
    # Remover Subnets
    if [ -n "$SUBNETS" ]; then
        log "🗑️  Removendo Subnets..."
        for subnet in $SUBNETS; do
            aws ec2 delete-subnet --subnet-id "$subnet" >/dev/null 2>&1 || true
            log "   ✅ Subnet $subnet removida"
        done
    fi
    
    # =============================================================================
    # REMOVER VPC
    # =============================================================================
    
    log "🗑️  Removendo VPC..."
    
    # Aguardar um pouco para garantir que recursos foram removidos
    sleep 10
    
    # Tentar remover a VPC
    if aws ec2 delete-vpc --vpc-id "$VPC_ID" >/dev/null 2>&1; then
        success "✅ VPC $VPC_ID removida com sucesso!"
    else
        warning "⚠️  Não foi possível remover a VPC automaticamente."
        warning "💡 Execute manualmente: aws ec2 delete-vpc --vpc-id $VPC_ID"
    fi
    
    echo
    success "🎉 Remoção concluída!"
    echo
    log "📊 Resumo da remoção:"
    log "   ✅ VPC $VPC_ID removida"
    log "   ✅ Recursos associados removidos"
}

# Executa a função principal
main "$@" 