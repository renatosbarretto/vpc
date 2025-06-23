#!/bin/bash

# 🗑️ Script de Destroy VPC Hub
# Versão simples para estudos

set -e

# Get the absolute path of the script's directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

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
    echo "🗑️ VPC Hub Destroy"
    echo "=================="
    echo
    
    # Verifica se Terraform está instalado
    if ! command -v terraform &> /dev/null; then
        error "❌ Terraform não encontrado. Instale primeiro."
    fi
    
    # Verifica se AWS CLI está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        error "❌ AWS CLI não configurado. Configure suas credenciais."
    fi
    
    success "✅ Dependências verificadas"
    
    # =============================================================================
    # DESTROY VPC HUB
    # =============================================================================
    
    log "🗑️ Destruindo VPC Hub..."
    cd "$PROJECT_ROOT/vpc/hub"
    
    # Verifica se existe estado do Terraform
    if [ ! -f "terraform.tfstate" ]; then
        warning "❌ Nenhum estado encontrado. Nada para destruir."
        exit 0
    fi
    
    log "📋 Mostrando plano de destruição..."
    terraform plan -destroy -out=destroy.tfplan
    
    echo
    read -p "🤔 Destruir VPC Hub? Esta ação é IRREVERSÍVEL! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "⚡ Destruindo VPC Hub..."
        terraform apply destroy.tfplan
        success "✅ VPC Hub destruída!"
    else
        warning "❌ Destroy cancelado"
        exit 1
    fi
    
    rm -f destroy.tfplan
    cd "$PROJECT_ROOT"
    
    echo
    success "🎉 Destroy concluído!"
    echo
    log "📊 Recursos destruídos:"
    log "   ✅ VPC Hub (10.0.0.0/16)"
    log "   ✅ 4 Subnets públicas"
    log "   ✅ 4 Subnets privadas"
    log "   ✅ 4 NAT Gateways"
    log "   ✅ Internet Gateway"
    log "   ✅ Transit Gateway"
    log "   ✅ Route Tables"
}

# Executa a função principal
main "$@" 