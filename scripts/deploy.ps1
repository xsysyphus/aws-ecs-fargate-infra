<#
.SYNOPSIS
    Este script automatiza o processo de build e deploy das imagens Docker para o Amazon ECS.
    Ele serve como uma alternativa local ao pipeline de CI/CD, para ser executado no PowerShell.
#>

# --- Configuração Manual ---
# Preencha estas variáveis com os valores da sua infraestrutura.
# Você pode obtê-las rodando 'terraform output' na pasta /terraform.
$awsRegion = "us-east-1"
$ecrRegistryUrl = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
$ecrRepositoryApi = "minha-api-api"
$ecrRepositoryNginx = "minha-api-nginx"
$ecsClusterName = "minha-api-cluster"
$ecsServiceApi = "minha-api-api-service"
$ecsServiceNginx = "minha-api-nginx-service"

Write-Host "Configuracoes carregadas:"
Write-Host " - Regiao: $awsRegion"
Write-Host " - ECR Registry: $ecrRegistryUrl"
Write-Host " - Cluster ECS: $ecsClusterName"
Write-Host ""

# --- Login no ECR ---
Write-Host "Efetuando login no Amazon ECR..."
aws ecr get-login-password --region $awsRegion | docker login --username AWS --password-stdin $ecrRegistryUrl
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Login no ECR falhou." -ForegroundColor Red
    exit 1
}
Write-Host "Login no ECR bem-sucedido." -ForegroundColor Green
Write-Host ""

# --- Build e Push da API ---
Write-Host "Iniciando build e push da imagem da API..."
$apiImageUri = "${ecrRegistryUrl}/${ecrRepositoryApi}:latest"
docker build -t $apiImageUri ./api
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Build da imagem da API falhou." -ForegroundColor Red
    exit 1
}
docker push $apiImageUri
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Push da imagem da API falhou." -ForegroundColor Red
    exit 1
}
Write-Host "Imagem da API enviada com sucesso." -ForegroundColor Green
Write-Host ""

# --- Build e Push do Nginx ---
Write-Host "Iniciando build e push da imagem do Nginx..."
$nginxImageUri = "${ecrRegistryUrl}/${ecrRepositoryNginx}:latest"
docker build -t $nginxImageUri ./nginx
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Build da imagem do Nginx falhou." -ForegroundColor Red
    exit 1
}
docker push $nginxImageUri
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Push da imagem do Nginx falhou." -ForegroundColor Red
    exit 1
}
Write-Host "Imagem do Nginx enviada com sucesso." -ForegroundColor Green
Write-Host ""

# --- Forçar Novo Deploy no ECS ---
Write-Host "Forcando um novo deploy dos servicos no ECS..."
aws ecs update-service --cluster $ecsClusterName --service $ecsServiceApi --force-new-deployment --region $awsRegion
aws ecs update-service --cluster $ecsClusterName --service $ecsServiceNginx --force-new-deployment --region $awsRegion
Write-Host ""
Write-Host "Solicitacao de deploy enviada com sucesso!" -ForegroundColor Green
Write-Host "Pode levar alguns minutos para as novas tarefas subirem. Monitore pelo Console do ECS."
