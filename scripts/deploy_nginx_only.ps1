# Script para deploy apenas da imagem do Nginx
# Este script faz build e push apenas da nova configuração do Nginx

Write-Host "Iniciando deploy da configuracao corrigida do Nginx..." -ForegroundColor Yellow

# Configurações - Preencha com seus valores
$awsRegion = "us-east-1"
$ecrRegistry = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
$ecsCluster = "minha-api-cluster"
$nginxService = "minha-api-nginx-service"
$nginxRepo = "minha-api-nginx"

# --- Login no ECR ---
Write-Host "Efetuando login no Amazon ECR..." -ForegroundColor Yellow
$loginCmd = wsl aws ecr get-login-password --region $awsRegion
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Login no ECR falhou." -ForegroundColor Red
    exit 1
}

$loginCmd | docker login --username AWS --password-stdin $ecrRegistry
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Login no ECR falhou." -ForegroundColor Red
    exit 1
}

Write-Host "Login no ECR bem-sucedido." -ForegroundColor Green

# --- Build e Push da imagem do Nginx ---
Write-Host "Iniciando build e push da imagem do Nginx..." -ForegroundColor Yellow

# Build da imagem
docker build -t ${nginxRepo}:latest ./nginx/
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Build da imagem do Nginx falhou." -ForegroundColor Red
    exit 1
}

# Tag da imagem
docker tag ${nginxRepo}:latest ${ecrRegistry}/${nginxRepo}:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Tag da imagem do Nginx falhou." -ForegroundColor Red
    exit 1
}

# Push da imagem
docker push ${ecrRegistry}/${nginxRepo}:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Push da imagem do Nginx falhou." -ForegroundColor Red
    exit 1
}

Write-Host "Build e push da imagem do Nginx bem-sucedidos." -ForegroundColor Green

# --- Forçar nova implantação do serviço ---
Write-Host "Forcando nova implantacao do servico Nginx..." -ForegroundColor Yellow

wsl aws ecs update-service --cluster $ecsCluster --service $nginxService --force-new-deployment --region $awsRegion | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Falha ao forcar nova implantacao." -ForegroundColor Red
    exit 1
}

Write-Host "Solicitacao de deploy enviada com sucesso!" -ForegroundColor Green
Write-Host "Pode levar alguns minutos para as novas tarefas subirem." -ForegroundColor Yellow
Write-Host "Monitore pelo Console do ECS." -ForegroundColor Yellow
