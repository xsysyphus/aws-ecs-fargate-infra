# Deploy Script para CDK - DevOps Interview Challenge
# Este script automatiza o deploy usando AWS CDK

param(
    [string]$ProjectName = "minha-api",
    [string]$Environment = "prod"
)

Write-Host "🚀 Iniciando deploy com AWS CDK..." -ForegroundColor Green
Write-Host "📋 Configurações:" -ForegroundColor Yellow
Write-Host "  - Projeto: $ProjectName" -ForegroundColor White
Write-Host "  - Ambiente: $Environment" -ForegroundColor White
Write-Host ""

# Verificar se Node.js está instalado
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js encontrado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js não encontrado. Instale Node.js 18+ primeiro." -ForegroundColor Red
    exit 1
}

# Verificar se CDK CLI está instalado
try {
    $cdkVersion = cdk --version
    Write-Host "✅ AWS CDK encontrado: $cdkVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CDK CLI não encontrado. Instalando..." -ForegroundColor Yellow
    npm install -g aws-cdk
}

# Verificar se AWS CLI está configurado
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS CLI configurado corretamente" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI não configurado. Execute 'aws configure' primeiro." -ForegroundColor Red
    exit 1
}

# Instalar dependências
Write-Host "📦 Instalando dependências..." -ForegroundColor Yellow
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Falha ao instalar dependências" -ForegroundColor Red
    exit 1
}

# Bootstrap CDK (se necessário)
Write-Host "🔧 Verificando bootstrap do CDK..." -ForegroundColor Yellow
cdk bootstrap --require-approval never

# Compilar TypeScript
Write-Host "🔨 Compilando TypeScript..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Falha na compilação TypeScript" -ForegroundColor Red
    exit 1
}

# Verificar diferenças
Write-Host "🔍 Verificando diferenças..." -ForegroundColor Yellow
cdk diff -c projectName=$ProjectName -c environment=$Environment

# Deploy
Write-Host "🚀 Iniciando deploy da infraestrutura..." -ForegroundColor Green
cdk deploy --require-approval never -c projectName=$ProjectName -c environment=$Environment

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Falha no deploy" -ForegroundColor Red
    exit 1
}

# Obter outputs
Write-Host "📋 Obtendo outputs da infraestrutura..." -ForegroundColor Yellow
cdk outputs -c projectName=$ProjectName -c environment=$Environment

Write-Host ""
Write-Host "✅ Deploy CDK concluído com sucesso!" -ForegroundColor Green
Write-Host "🔗 Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Use os outputs acima para configurar scripts/deploy.ps1" -ForegroundColor White
Write-Host "  2. Execute ./scripts/deploy.ps1 para fazer deploy das aplicações" -ForegroundColor White
Write-Host "  3. Teste a API usando os comandos no README.md" -ForegroundColor White
