#!/bin/bash

# 🚀 Script de Deploy VPC Hub
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
    echo "🌐 VPC Hub Deploy"
    echo "================="
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
    # DEPLOY VPC HUB
    # =============================================================================
    
    log "🚀 Deployando VPC Hub..."
    cd "$PROJECT_ROOT/vpc/hub"
    
    log "📦 Inicializando Terraform..."
    terraform init
    
    log "✅ Validando configuração..."
    terraform validate
    
    log "📋 Mostrando plano..."
    terraform plan -out=tfplan
    
    echo
    read -p "🤔 Aplicar VPC Hub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "⚡ Aplicando VPC Hub..."
        terraform apply tfplan
        success "✅ VPC Hub criada!"
    else
        warning "❌ Deploy cancelado"
        exit 1
    fi
    
    rm -f tfplan
    cd "$PROJECT_ROOT"
    
    echo
    success "🎉 Deploy concluído!"
    echo
    log "📊 Resumo:"
    log "   ✅ VPC Hub criada (10.0.0.0/16)"
    log "   ✅ 4 Subnets públicas (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24, 10.0.4.0/24)"
    log "   ✅ 4 Subnets privadas (10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24)"
    log "   ✅ 4 Availability Zones (us-east-1a, us-east-1b, us-east-1c, us-east-1d)"
    log "   ✅ Internet Gateway configurado"
    log "   ✅ 4 NAT Gateways configurados (um por AZ)"
    log "   ✅ Transit Gateway configurado"
}

# Executa a função principal
main "$@" 