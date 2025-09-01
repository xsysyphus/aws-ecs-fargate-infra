#!/bin/bash

# ===============================================
# Script para Geração de Certificados mTLS
# ===============================================
# Este script gera todos os certificados necessários para mTLS:
# - Certificate Authority (CA) privada
# - Certificado do servidor (Nginx)
# - Certificado do cliente (para testes)

echo "🔐 Iniciando geração de certificados mTLS..."

# --- Configurações ---
# Modifique estas variáveis conforme necessário
COUNTRY="BR"
STATE="Sao Paulo"
CITY="Sao Paulo"
ORG_CA="Minha CA"
ORG_SERVER="Meu Servidor"
ORG_CLIENT="Meu Cliente"
COMMON_NAME_SERVER="api.exemplo.com"

# Criar diretório se não existir
mkdir -p $(dirname "$0")
cd $(dirname "$0")

echo "📁 Trabalhando no diretório: $(pwd)"

# --- 1. Gerar Certificate Authority (CA) ---
echo "🏭 Gerando Certificate Authority (CA)..."
openssl req -new -x509 -days 3650 -extensions v3_ca \
  -keyout ca.key -out ca.crt \
  -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_CA/CN=Minha Autoridade Certificadora" \
  -config <(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]

[v3_ca]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign
EOF
  )

if [ $? -eq 0 ]; then
    echo "✅ CA gerada com sucesso!"
else
    echo "❌ Erro ao gerar CA"
    exit 1
fi

# --- 2. Gerar chave privada do servidor ---
echo "🔑 Gerando chave privada do servidor..."
openssl genrsa -out server.key 2048

if [ $? -eq 0 ]; then
    echo "✅ Chave do servidor gerada!"
else
    echo "❌ Erro ao gerar chave do servidor"
    exit 1
fi

# --- 3. Gerar Certificate Signing Request (CSR) do servidor ---
echo "📝 Gerando CSR do servidor..."
openssl req -new -key server.key -out server.csr \
  -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_SERVER/CN=$COMMON_NAME_SERVER"

if [ $? -eq 0 ]; then
    echo "✅ CSR do servidor gerado!"
else
    echo "❌ Erro ao gerar CSR do servidor"
    exit 1
fi

# --- 4. Assinar certificado do servidor com CA ---
echo "✍️  Assinando certificado do servidor..."
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 825

if [ $? -eq 0 ]; then
    echo "✅ Certificado do servidor assinado!"
else
    echo "❌ Erro ao assinar certificado do servidor"
    exit 1
fi

# --- 5. Criar fullchain para Nginx ---
echo "🔗 Criando fullchain..."
cat server.crt ca.crt > server.fullchain.crt
echo "✅ Fullchain criado!"

# --- 6. Gerar certificado de cliente ---
echo "👤 Gerando certificado de cliente..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLIENT_KEY="cliente-${TIMESTAMP}.key"
CLIENT_CRT="cliente-${TIMESTAMP}.crt"

# Gerar chave privada do cliente
openssl genrsa -out "$CLIENT_KEY" 2048

# Gerar CSR do cliente
openssl req -new -key "$CLIENT_KEY" -out cliente.csr \
  -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_CLIENT/CN=Cliente Autorizado"

# Assinar certificado do cliente
openssl x509 -req -in cliente.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out "$CLIENT_CRT" -days 825

if [ $? -eq 0 ]; then
    echo "✅ Certificado de cliente gerado: $CLIENT_CRT"
else
    echo "❌ Erro ao gerar certificado de cliente"
    exit 1
fi

# --- 7. Limpar arquivos temporários ---
echo "🧹 Limpando arquivos temporários..."
rm -f server.csr cliente.csr

# --- 8. Mostrar resumo ---
echo ""
echo "🎉 CERTIFICADOS GERADOS COM SUCESSO!"
echo "================================================"
echo "📁 Arquivos criados:"
echo "  - ca.crt (Certificate Authority)"
echo "  - ca.key (Chave da CA - MANTENHA SEGURA!)"
echo "  - server.crt (Certificado do servidor)"
echo "  - server.key (Chave do servidor)"
echo "  - server.fullchain.crt (Servidor + CA)"
echo "  - $CLIENT_CRT (Certificado do cliente)"
echo "  - $CLIENT_KEY (Chave do cliente)"
echo ""
echo "🔒 IMPORTANTE:"
echo "  - Mantenha ca.key e server.key seguros!"
echo "  - Use $CLIENT_CRT e $CLIENT_KEY para testes"
echo "  - Para gerar mais clientes, execute este script novamente"
echo ""
echo "🧪 Teste com curl:"
echo "curl -k --cert ./$CLIENT_CRT --key ./$CLIENT_KEY https://[SEU_NLB_DNS]/api/webhook"
echo ""
