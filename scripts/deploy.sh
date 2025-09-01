#!/bin/bash

# Este script automatiza o processo de build e deploy das imagens Docker para o Amazon ECS.
# Ele serve como uma alternativa local ao pipeline de CI/CD.

# --- Configuração ---
# O script tentará obter os nomes dos recursos dos outputs do Terraform.
# Certifique-se de que seu terminal esteja no diretório raiz do projeto.

echo "🔎 Obtendo configurações do Terraform..."
AWS_REGION=$(terraform -chdir=./terraform output -raw aws_region)
ECR_REGISTRY_URL=$(terraform -chdir=./terraform output -raw ecr_registry_url)
ECR_REPOSITORY_API=$(terraform -chdir=./terraform output -raw ecr_repository_api_name)
ECR_REPOSITORY_NGINX=$(terraform -chdir=./terraform output -raw ecr_repository_nginx_name)
ECS_CLUSTER_NAME=$(terraform -chdir=./terraform output -raw ecs_cluster_name)
ECS_SERVICE_API=$(terraform -chdir=./terraform output -raw ecs_service_api_name)
ECS_SERVICE_NGINX=$(terraform -chdir=./terraform output -raw ecs_service_nginx_name)

# Validação
if [ -z "$AWS_REGION" ] || [ -z "$ECR_REGISTRY_URL" ]; then
    echo "❌ Erro: Não foi possível obter os outputs do Terraform. Execute 'terraform apply' primeiro."
    exit 1
fi

echo "✅ Configurações carregadas com sucesso."
echo "   - Região: $AWS_REGION"
echo "   - ECR Registry: $ECR_REGISTRY_URL"
echo "   - Cluster ECS: $ECS_CLUSTER_NAME"
echo ""

# --- Login no ECR ---
echo "🔑 Efetuando login no Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY_URL
if [ $? -ne 0 ]; then
    echo "❌ Erro: Login no ECR falhou."
    exit 1
fi
echo "✅ Login no ECR bem-sucedido."
echo ""

# --- Build e Push da API ---
echo "🚀 Iniciando build e push da imagem da API..."
docker build -t $ECR_REGISTRY_URL/$ECR_REPOSITORY_API:latest ./api
if [ $? -ne 0 ]; then
    echo "❌ Erro: Build da imagem da API falhou."
    exit 1
fi
docker push $ECR_REGISTRY_URL/$ECR_REPOSITORY_API:latest
if [ $? -ne 0 ]; then
    echo "❌ Erro: Push da imagem da API falhou."
    exit 1
fi
echo "✅ Imagem da API enviada com sucesso."
echo ""

# --- Build e Push do Nginx ---
echo "🚀 Iniciando build e push da imagem do Nginx..."
docker build -t $ECR_REGISTRY_URL/$ECR_REPOSITORY_NGINX:latest ./nginx
if [ $? -ne 0 ]; then
    echo "❌ Erro: Build da imagem do Nginx falhou."
    exit 1
fi
docker push $ECR_REGISTRY_URL/$ECR_REPOSITORY_NGINX:latest
if [ $? -ne 0 ]; then
    echo "❌ Erro: Push da imagem do Nginx falhou."
    exit 1
fi
echo "✅ Imagem do Nginx enviada com sucesso."
echo ""

# --- Forçar Novo Deploy no ECS ---
echo "🔄 Forçando um novo deploy dos serviços no ECS..."
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_API --force-new-deployment --region $AWS_REGION
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NGINX --force-new-deployment --region $AWS_REGION
echo ""
echo "✅ Solicitação de deploy enviada com sucesso!"
echo "   Pode levar alguns minutos para as novas tarefas subirem. Monitore pelo Console do ECS."
