# 🚀 AWS CDK Implementation - DevOps Interview Challenge

Esta é uma implementação alternativa usando **AWS CDK (Cloud Development Kit)** em TypeScript, equivalente à implementação Terraform existente.

## 📋 Pré-requisitos

- Node.js 18+ instalado
- AWS CLI configurado
- AWS CDK CLI instalado globalmente: `npm install -g aws-cdk`
- Docker Desktop rodando

## 🔧 Configuração Inicial

### 1. Instalar Dependências
```bash
cd cdk
npm install
```

### 2. Bootstrap CDK (primeira vez apenas)
```bash
cdk bootstrap
```

### 3. Configurar Contexto (Opcional)
```bash
# Definir nome do projeto
cdk deploy -c projectName=minha-api -c environment=prod
```

## 🚀 Deploy

### Deploy Completo
```bash
# Verificar o que será criado
cdk diff

# Deploy de toda a infraestrutura
cdk deploy

# Deploy com aprovação automática
cdk deploy --require-approval never
```

### Deploy Específico
```bash
# Deploy apenas da stack principal
cdk deploy DevOpsInterviewStack
```

## 📊 Recursos Criados

### Networking
- **VPC** com subnets públicas e privadas
- **NAT Gateways** para conectividade de saída
- **Security Groups** para Nginx e API

### Container Services
- **ECS Fargate Cluster** 
- **ECR Repositories** para API e Nginx
- **ECS Services** com auto-scaling
- **Service Discovery** (AWS Cloud Map)

### Load Balancing
- **Network Load Balancer** com SSL passthrough
- **Target Groups** para distribuição de tráfego

### Monitoring
- **CloudWatch Log Groups**
- **CloudWatch Dashboard** com métricas
- **Container Insights** habilitado

### Security
- **WAF v2** com regras de proteção
- **IAM Roles** com least privilege
- **Security Groups** granulares

## 🔍 Comandos Úteis

### Desenvolvimento
```bash
# Compilar TypeScript
npm run build

# Modo watch (recompila automaticamente)
npm run watch

# Executar testes
npm test

# Verificar sintaxe CDK
cdk synth
```

### Gerenciamento
```bash
# Listar todas as stacks
cdk list

# Ver diferenças antes do deploy
cdk diff

# Destruir infraestrutura
cdk destroy

# Ver outputs das stacks
cdk outputs
```

## 📤 Outputs Importantes

Após o deploy, você receberá:

- **VpcId**: ID da VPC criada
- **ClusterName**: Nome do cluster ECS
- **NlbDnsName**: DNS do Network Load Balancer
- **ApiRepositoryUri**: URI do repositório ECR da API
- **NginxRepositoryUri**: URI do repositório ECR do Nginx
- **ServiceDiscoveryNamespace**: Namespace do Service Discovery

## 🔄 Deploy das Aplicações

Após criar a infraestrutura, use os mesmos scripts de deploy:

```bash
# Obter URIs dos repositórios
aws cloudformation describe-stacks --stack-name DevOpsInterviewStack --query 'Stacks[0].Outputs'

# Atualizar scripts/deploy.ps1 com os novos valores
# Executar deploy das imagens
./scripts/deploy.ps1
```

## 🆚 CDK vs Terraform

### Vantagens do CDK:
- **Type Safety**: TypeScript com IntelliSense
- **Programática**: Loops, condições, funções
- **AWS Native**: Constructs oficiais da AWS
- **Testing**: Framework de testes integrado
- **Reutilização**: Componentes modulares

### Vantagens do Terraform:
- **Multi-Cloud**: Suporte a múltiplos provedores
- **HCL**: Linguagem declarativa simples
- **State Management**: Gerenciamento de estado robusto
- **Community**: Ecossistema maduro

## 🎯 Equivalência com Terraform

Esta implementação CDK é **funcionalmente equivalente** ao Terraform:

| Recurso | Terraform | CDK |
|---------|-----------|-----|
| VPC | `aws_vpc` | `ec2.Vpc` |
| ECS | `aws_ecs_*` | `ecs.*` |
| NLB | `aws_lb` | `elbv2.NetworkLoadBalancer` |
| ECR | `aws_ecr_repository` | `ecr.Repository` |
| CloudWatch | `aws_cloudwatch_*` | `cloudwatch.*` |
| WAF | `aws_wafv2_*` | `wafv2.*` |

## 🔧 Customização

### Variáveis de Contexto
```bash
# Deploy com configurações customizadas
cdk deploy \
  -c projectName=meu-projeto \
  -c environment=staging
```

### Modificar Recursos
Edite `lib/devops-interview-stack.ts` e execute:
```bash
cdk diff  # Ver mudanças
cdk deploy  # Aplicar mudanças
```

## 🆘 Troubleshooting

### Erro de Bootstrap
```bash
# Re-bootstrap se necessário
cdk bootstrap --force
```

### Conflito de Nomes
```bash
# Usar sufixo único
cdk deploy -c projectName=minha-api-$(date +%s)
```

### Rollback
```bash
# Destruir e recriar
cdk destroy
cdk deploy
```

---

**🎯 Esta implementação CDK oferece a mesma funcionalidade que o Terraform, com a flexibilidade adicional de uma linguagem de programação completa!**
