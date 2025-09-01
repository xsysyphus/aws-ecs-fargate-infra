# Infraestrutura para Aplicações em Contêineres com AWS ECS Fargate

## Tabela de Conteúdo

1. [Descrição do Projeto](#descrição-do-projeto)
2. [Arquitetura](#arquitetura)
3. [Configuração do Ambiente](#configuração-do-ambiente)
4. [Pipeline CI/CD](#pipeline-cicd)
5. [Gerenciamento de Infraestrutura](#gerenciamento-de-infraestrutura)
6. [Monitoramento e Logs](#monitoramento-e-logs)
7. [Segurança](#segurança)
8. [Testes e Qualidade](#testes-e-qualidade)
9. [Como Contribuir](#como-contribuir)
10. [Licença e Contato](#licença-e-contato)

---

## Descrição do Projeto

Este projeto tem como objetivo provisionar e gerenciar uma infraestrutura completa na AWS para hospedar aplicações em contêineres utilizando **Amazon ECS (Elastic Container Service)** com **Fargate**. A solução é projetada para ser escalável, segura e altamente disponível, automatizando o máximo de processos possível através de Infraestrutura como Código (IaC).

- **Objetivo:** Automatizar o deploy de uma infraestrutura robusta para aplicações conteinerizadas na AWS.
- **Contexto:** Ideal para projetos que necessitam de um ambiente de nuvem moderno, sem o gerenciamento manual de servidores (serverless), com escalabilidade automática e resiliência.
- **Público-alvo:** Desenvolvedores DevOps, engenheiros de infraestrutura e equipes de desenvolvimento que buscam uma forma padronizada e eficiente de publicar suas aplicações.

---

## Arquitetura

A arquitetura foi desenhada para garantir a separação de responsabilidades, segurança e escalabilidade.

### Fluxo da Aplicação

1.  O tráfego de usuários chega a um **Application Load Balancer (ALB)**, que distribui as requisições.
2.  O ALB encaminha o tráfego para os contêineres da aplicação rodando em um cluster **ECS Fargate**.
3.  O Fargate gerencia a execução dos contêineres, escalando a quantidade de tarefas (contêineres) conforme a demanda.
4.  As imagens Docker das aplicações são armazenadas de forma segura no **Amazon ECR (Elastic Container Registry)**.
5.  Toda a infraestrutura é provisionada e gerenciada pelo **Terraform**.

### Diagrama da Arquitetura

```mermaid
graph TD
    A[Usuário] --> B{Application Load Balancer};
    B --> C{ECS Service};
    C --> D[Task 1 (Container)];
    C --> E[Task 2 (Container)];
    C -- "Puxa imagem" --> F[Imagem Docker ECR];
    G[Terraform] -- "Provisiona" --> B;
    G -- "Provisiona" --> C;
    G -- "Provisiona" --> F;
```

### Tecnologias Utilizadas

-   **AWS:**
    -   **ECS (Elastic Container Service) com Fargate:** Orquestração de contêineres.
    -   **ECR (Elastic Container Registry):** Repositório de imagens Docker.
    -   **VPC (Virtual Private Cloud):** Rede isolada para os recursos.
    -   **Application Load Balancer (ALB):** Distribuição de tráfego.
    -   **CloudWatch:** Monitoramento e logs.
    -   **WAF (Web Application Firewall):** Segurança contra ataques web.
-   **Infraestrutura como Código (IaC):**
    -   **Terraform:** Ferramenta para provisionar e gerenciar a infraestrutura.
-   **Contêineres:**
    -   **Docker:** Criação e gerenciamento de contêineres.
    -   **Nginx:** Utilizado como proxy reverso ou web server dentro de um contêiner.

---

## Configuração do Ambiente

### Pré-requisitos

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas e configuradas:

-   [AWS CLI](https://aws.amazon.com/cli/): Autenticado com permissões para criar os recursos necessários.
-   [Terraform](https://www.terraform.io/downloads.html): Versão `1.0.0` ou superior.
-   [Docker](https://www.docker.com/get-started): Para construir e enviar imagens para o ECR.
-   [Git](https://git-scm.com/): Para controle de versão.

### Instalação

1.  **Clone o repositório:**
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd aws-ecs-fargate-infra
    ```

2.  **Configure as credenciais da AWS:**
    Certifique-se de que suas credenciais da AWS estão configuradas corretamente. Você pode usar o comando `aws configure` ou definir as variáveis de ambiente:
    ```bash
    export AWS_ACCESS_KEY_ID="SUA_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="SUA_SECRET_KEY"
    export AWS_REGION="sua-regiao" # Ex: us-east-1
    ```

### Variáveis de Ambiente

As configurações principais da infraestrutura são gerenciadas através do arquivo `terraform/variables.tf`. Você pode criar um arquivo `terraform.tfvars` para substituir os valores padrão sem modificar o código original.

**Exemplo de `terraform.tfvars`:**

```hcl
# terraform/terraform.tfvars

aws_region      = "us-east-1"
project_name    = "meu-projeto"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
```

---

## Pipeline CI/CD

O processo de integração e entrega contínua é gerenciado por scripts localizados no diretório `scripts/`.

### Etapas do Pipeline

1.  **Build:** A imagem Docker da aplicação é construída.
2.  **Push:** A imagem é enviada para o repositório ECR na AWS.
3.  **Deploy:** O Terraform é executado para aplicar as mudanças na infraestrutura e atualizar o serviço ECS com a nova imagem.

### Comandos de Deploy

Para executar o deploy completo, utilize o script principal:

```powershell
# No Windows (PowerShell)
.\scripts\deploy.ps1 -env "staging"

# No Linux/macOS (Bash)
./scripts/deploy.sh staging
```

O script `deploy_nginx_only.ps1` é específico para o Nginx e pode ser usado para atualizações que afetam apenas este componente.

### Ferramentas

-   **PowerShell / Bash:** Para a orquestração do deploy.
-   **Docker:** Para o gerenciamento do ciclo de vida dos contêineres.
-   **Terraform:** Para o provisionamento da infraestrutura.

---

## Gerenciamento de Infraestrutura

A infraestrutura é totalmente gerenciada como código usando **Terraform**. Os arquivos de configuração estão no diretório `terraform/`.

### Estrutura dos Arquivos Terraform

-   `main.tf`: Provedor AWS e configurações gerais.
-   `network.tf`: Definição da VPC, sub-redes, tabelas de rotas e gateways.
-   `security.tf`: Security Groups para controlar o tráfego.
-   `ecr.tf`: Criação do repositório ECR.
-   `ecs.tf`: Definição do cluster ECS, task definitions e serviços.
-   `alb.tf`: Configuração do Application Load Balancer.
-   `monitoring.tf`: Recursos de monitoramento (CloudWatch).
-   `waf.tf`: Configuração do Web Application Firewall.
-   `variables.tf`: Variáveis de entrada para customização.
-   `outputs.tf`: Saídas, como o DNS do Load Balancer.

### Como Aplicar a Infraestrutura

1.  **Navegue até o diretório do Terraform:**
    ```bash
    cd terraform
    ```

2.  **Inicialize o Terraform:**
    ```bash
    terraform init
    ```

3.  **Planeje as mudanças:**
    ```bash
    terraform plan
    ```

4.  **Aplique as mudanças:**
    ```bash
    terraform apply
    ```

---

## Monitoramento e Logs

### Ferramentas

-   **AWS CloudWatch:** É a ferramenta principal para coletar logs e métricas.
    -   **Logs:** Os logs dos contêineres são enviados automaticamente para o CloudWatch Logs, organizados por grupos de logs.
    -   **Métricas:** Métricas de uso de CPU, memória do serviço ECS, e o estado do ALB estão disponíveis no CloudWatch Metrics.
-   **AWS X-Ray (Opcional):** Pode ser integrado para rastreamento de requisições e análise de performance.

### Dashboards e Alertas

Recomenda-se a criação de dashboards no CloudWatch para visualizar as principais métricas de saúde da aplicação em tempo real. Além disso, podem ser configurados alertas (Alarms) para notificar a equipe em caso de anomalias, como:

-   Uso de CPU/memória acima de um limite.
-   Número excessivo de respostas de erro (HTTP 5xx) no ALB.
-   Health checks falhando.

---

## Segurança

### Boas Práticas

-   **Princípio do Menor Privilégio:** As permissões IAM para os serviços e tarefas ECS são restritas ao mínimo necessário.
-   **Segredos:** Dados sensíveis, como senhas de banco de dados e chaves de API, devem ser gerenciados pelo **AWS Secrets Manager** ou **Parameter Store**, e não hard-coded.
-   **Rede:** A aplicação roda em sub-redes privadas, sem acesso direto da internet. O acesso é mediado pelo ALB em sub-redes públicas.
-   **Security Groups:** Atuam como um firewall virtual para controlar o tráfego de entrada e saída das tarefas ECS e do ALB.

### Autenticação e Autorização

-   A autenticação de usuários na aplicação é de responsabilidade da própria aplicação.
-   Para acesso à infraestrutura AWS, utiliza-se o **IAM (Identity and Access Management)**, com políticas que definem quem pode fazer o quê.

### Gerenciamento de Segredos

Para injetar segredos nos contêineres de forma segura, utilize a integração do ECS com o AWS Secrets Manager.

**Exemplo em uma Task Definition:**

```json
"secrets": [
    {
        "name": "DATABASE_PASSWORD",
        "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:SECRET_NAME-XXXXXX"
    }
]
```

---

## Testes e Qualidade

A qualidade do código é garantida através de uma suíte de testes automatizados e ferramentas de análise estática.

### Testes Automatizados

-   **Testes Unitários:** Utilizamos [Jest](https://jestjs.io/) para testes unitários. Para executar os testes, rode o comando na raiz do projeto da aplicação:
    ```bash
    npm test
    ```

-   **Testes de Integração:** Os testes de integração validam a interação entre os diferentes serviços e componentes da aplicação. Eles são executados com [Jest](https://jestjs.io/) e [Supertest](https://github.com/ladjs/supertest).
    ```bash
    npm run test:integration
    ```

-   **Testes End-to-End (E2E):** Os fluxos completos do usuário são validados utilizando [Cypress](https://www.cypress.io/). Para abrir o executor de testes do Cypress:
    ```bash
    npm run cypress:open
    ```

### Cobertura de Código (Code Coverage)

A cobertura de testes é gerada pelo Jest. Nosso objetivo é manter uma cobertura de no mínimo **80%**. Para gerar o relatório de cobertura, execute:
```bash
npm test -- --coverage
```
O relatório detalhado estará disponível no diretório `coverage/`.

### Linting

-   **Código da Aplicação:** Usamos [ESLint](https://eslint.org/) para manter um padrão de código consistente e evitar erros comuns. Para verificar os arquivos:
    ```bash
    npm run lint
    ```
    Para corrigir automaticamente os problemas:
    ```bash
    npm run lint:fix
    ```

-   **Terraform:** Para garantir a qualidade e a formatação do código de infraestrutura, utilizamos os comandos nativos do Terraform:
    ```bash
    # Formata o código
    terraform fmt

    # Valida a sintaxe
    terraform validate
    ```

---

## Como Contribuir

Agradecemos o seu interesse em contribuir! Para garantir um processo eficiente, por favor, siga estas diretrizes:

1.  **Faça um Fork** do repositório.
2.  **Crie uma Nova Branch:** `git checkout -b feature/sua-feature`.
3.  **Faça suas Alterações:** Siga as boas práticas de código e adicione testes, se aplicável.
4.  **Envie um Pull Request (PR):** Descreva claramente as mudanças e o motivo.
5.  Aguarde a revisão do código.

---

## Licença e Contato

### Contato

-   **Nome do Mantenedor:** Fidêncio Vieira
-   **Email:** fidenciovieira@hotmail.com
-   **GitHub:** [xsysyphus](https://github.com/xsysyphus)
