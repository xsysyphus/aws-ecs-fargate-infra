#!/bin/bash

# Este script automatiza a geração de todos os certificados necessários para o mTLS.
# USO: ./gerar_certificados.sh <common_name_do_servidor>
# Exemplo: ./gerar_certificados.sh api.bodyharmony.life

# --- Validação do Input ---
if [ -z "$1" ]; then
    echo "Erro: Forneça o Common Name (domínio) para o certificado do servidor como primeiro argumento."
    echo "Exemplo de uso: ./gerar_certificados.sh api.meudominio.com"
    exit 1
fi

SERVER_CN=$1
CERT_DIR="certs"

# --- Criação do Diretório ---
mkdir -p $CERT_DIR
echo "Diretório '$CERT_DIR' criado."

# --- Configurações (para modo não-interativo) ---
CA_SUBJ="/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Minha CA/CN=Minha Autoridade Certificadora"
SERVER_SUBJ="/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Meu Servidor/CN=${SERVER_CN}"
CLIENT_SUBJ="/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Meu Cliente/CN=Cliente de Teste"

# --- Geração dos Certificados ---

echo "1. Gerando a Chave Privada da CA (ca.key)..."
openssl genrsa -out $CERT_DIR/ca.key 2048

echo "2. Gerando o Certificado da CA (ca.crt)..."
openssl req -x509 -new -nodes -key $CERT_DIR/ca.key -sha256 -days 1024 -out $CERT_DIR/ca.crt -subj "$CA_SUBJ"

echo "3. Gerando a Chave Privada do Servidor (server.key)..."
openssl genrsa -out $CERT_DIR/server.key 2048

echo "4. Gerando o Pedido de Assinatura (CSR) do Servidor (server.csr)..."
openssl req -new -key $CERT_DIR/server.key -out $CERT_DIR/server.csr -subj "$SERVER_SUBJ"

echo "5. Assinando o Certificado do Servidor com a CA (server.crt)..."
openssl x509 -req -in $CERT_DIR/server.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/server.crt -days 500 -sha256

# --- Geração do Certificado de Cliente Único ---
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CLIENT_ID="cliente-${TIMESTAMP}"
CLIENT_CN="Cliente de Teste ${TIMESTAMP}"
CLIENT_KEY_FILE="${CERT_DIR}/${CLIENT_ID}.key"
CLIENT_CSR_FILE="${CERT_DIR}/${CLIENT_ID}.csr"
CLIENT_CRT_FILE="${CERT_DIR}/${CLIENT_ID}.crt"
CLIENT_SUBJ="/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Meu Cliente/CN=${CLIENT_CN}"

echo "6. Gerando a Chave Privada do Cliente (${CLIENT_ID}.key)..."
openssl genrsa -out $CLIENT_KEY_FILE 2048

echo "7. Gerando o Pedido de Assinatura (CSR) do Cliente (${CLIENT_ID}.csr)..."
openssl req -new -key $CLIENT_KEY_FILE -out $CLIENT_CSR_FILE -subj "$CLIENT_SUBJ"

echo "8. Assinando o Certificado do Cliente com a CA (${CLIENT_ID}.crt)..."
openssl x509 -req -in $CLIENT_CSR_FILE -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CLIENT_CRT_FILE -days 500 -sha256

# --- Limpeza ---
echo "Limpando arquivos intermediários (.csr, .srl)..."
rm $CERT_DIR/*.csr
rm $CERT_DIR/*.srl

echo ""
echo "✅ Processo concluído!"
echo "   - Certificados do Servidor gerados em '$CERT_DIR/' (server.crt, server.key, ca.crt)."
echo "   - Novo certificado de CLIENTE ÚNICO gerado:"
echo "     - Chave: ${CLIENT_KEY_FILE}"
echo "     - Certificado: ${CLIENT_CRT_FILE}"
