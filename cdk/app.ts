#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AppInfraStack } from './lib/app-infra-stack';

const app = new cdk.App();

// Configurações do projeto
const projectName = app.node.tryGetContext('projectName') || 'minha-api';
const environment = app.node.tryGetContext('environment') || 'prod';

new AppInfraStack(app, 'AppInfraStack', {
  projectName,
  environment,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Infraestrutura para aplicação com ECS Fargate e Nginx Gateway'
});
