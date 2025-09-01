import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as wafv2 from 'aws-cdk-lib/aws-wafv2';
import { Construct } from 'constructs';

export interface AppInfraStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
}

export class AppInfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AppInfraStackProps) {
    super(scope, id, props);

    const { projectName, environment } = props;

    // ===== VPC e Networking =====
    const vpc = new ec2.Vpc(this, 'VPC', {
      vpcName: `${projectName}-vpc`,
      cidr: '10.0.0.0/16',
      maxAzs: 2,
      natGateways: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
    });

    // ===== Service Discovery =====
    const namespace = new servicediscovery.PrivateDnsNamespace(this, 'ServiceDiscovery', {
      name: `${projectName}.local`,
      vpc,
      description: `Service Discovery para ${projectName}`,
    });

    // ===== Security Groups =====
    const nginxSecurityGroup = new ec2.SecurityGroup(this, 'NginxSecurityGroup', {
      vpc,
      description: 'Security Group para Nginx Gateway',
      allowAllOutbound: true,
    });

    nginxSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(443),
      'HTTPS traffic from anywhere'
    );

    const apiSecurityGroup = new ec2.SecurityGroup(this, 'ApiSecurityGroup', {
      vpc,
      description: 'Security Group para API Python',
      allowAllOutbound: true,
    });

    apiSecurityGroup.addIngressRule(
      nginxSecurityGroup,
      ec2.Port.tcp(5000),
      'HTTP traffic from Nginx'
    );

    // ===== ECR Repositories =====
    const apiRepository = new ecr.Repository(this, 'ApiRepository', {
      repositoryName: `${projectName}-api`,
      imageScanOnPush: true,
      lifecycleRules: [
        {
          maxImageCount: 10,
          description: 'Keep only 10 images',
        },
      ],
    });

    const nginxRepository = new ecr.Repository(this, 'NginxRepository', {
      repositoryName: `${projectName}-nginx`,
      imageScanOnPush: true,
      lifecycleRules: [
        {
          maxImageCount: 10,
          description: 'Keep only 10 images',
        },
      ],
    });

    // ===== ECS Cluster =====
    const cluster = new ecs.Cluster(this, 'EcsCluster', {
      clusterName: `${projectName}-cluster`,
      vpc,
      containerInsights: true,
    });

    // ===== CloudWatch Log Groups =====
    const apiLogGroup = new logs.LogGroup(this, 'ApiLogGroup', {
      logGroupName: `/ecs/${projectName}/api`,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const nginxLogGroup = new logs.LogGroup(this, 'NginxLogGroup', {
      logGroupName: `/ecs/${projectName}/nginx`,
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ===== IAM Roles =====
    const taskExecutionRole = new iam.Role(this, 'TaskExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });

    const taskRole = new iam.Role(this, 'TaskRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });

    // ===== ECS Task Definitions =====
    const apiTaskDefinition = new ecs.FargateTaskDefinition(this, 'ApiTaskDefinition', {
      family: `${projectName}-api-task`,
      cpu: 256,
      memoryLimitMiB: 512,
      executionRole: taskExecutionRole,
      taskRole: taskRole,
    });

    const apiContainer = apiTaskDefinition.addContainer('ApiContainer', {
      containerName: `${projectName}-api-container`,
      image: ecs.ContainerImage.fromEcrRepository(apiRepository, 'latest'),
      portMappings: [
        {
          containerPort: 5000,
          protocol: ecs.Protocol.TCP,
        },
      ],
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'api',
        logGroup: apiLogGroup,
      }),
      environment: {
        PORT: '5000',
        ENV: environment,
      },
      healthCheck: {
        command: ['CMD-SHELL', 'curl -f http://localhost:5000/health || exit 1'],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    const nginxTaskDefinition = new ecs.FargateTaskDefinition(this, 'NginxTaskDefinition', {
      family: `${projectName}-nginx-task`,
      cpu: 256,
      memoryLimitMiB: 512,
      executionRole: taskExecutionRole,
      taskRole: taskRole,
    });

    const nginxContainer = nginxTaskDefinition.addContainer('NginxContainer', {
      containerName: `${projectName}-nginx-container`,
      image: ecs.ContainerImage.fromEcrRepository(nginxRepository, 'latest'),
      portMappings: [
        {
          containerPort: 443,
          protocol: ecs.Protocol.TCP,
        },
      ],
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'nginx',
        logGroup: nginxLogGroup,
      }),
      healthCheck: {
        command: ['CMD-SHELL', 'curl -k -f https://localhost:443/health || exit 1'],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    // ===== ECS Services =====
    const apiService = new ecs.FargateService(this, 'ApiService', {
      serviceName: `${projectName}-api-service`,
      cluster,
      taskDefinition: apiTaskDefinition,
      desiredCount: 2,
      assignPublicIp: false,
      securityGroups: [apiSecurityGroup],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      enableExecuteCommand: true,
      cloudMapOptions: {
        name: 'api',
        cloudMapNamespace: namespace,
        dnsRecordType: servicediscovery.DnsRecordType.A,
        dnsTtl: cdk.Duration.seconds(60),
      },
    });

    const nginxService = new ecs.FargateService(this, 'NginxService', {
      serviceName: `${projectName}-nginx-service`,
      cluster,
      taskDefinition: nginxTaskDefinition,
      desiredCount: 2,
      assignPublicIp: false,
      securityGroups: [nginxSecurityGroup],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      enableExecuteCommand: true,
    });

    // ===== Network Load Balancer =====
    const nlb = new elbv2.NetworkLoadBalancer(this, 'NetworkLoadBalancer', {
      loadBalancerName: `${projectName}-nlb`,
      vpc,
      internetFacing: true,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    const targetGroup = new elbv2.NetworkTargetGroup(this, 'NginxTargetGroup', {
      targetGroupName: `${projectName}-nginx-tg`,
      port: 443,
      protocol: elbv2.Protocol.TCP,
      vpc,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        protocol: elbv2.Protocol.HTTPS,
        path: '/health',
        port: '443',
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 2,
        timeout: cdk.Duration.seconds(10),
        interval: cdk.Duration.seconds(30),
      },
    });

    const listener = nlb.addListener('NlbListener', {
      port: 443,
      protocol: elbv2.Protocol.TCP,
      defaultTargetGroups: [targetGroup],
    });

    // Attach ECS Service to Target Group
    nginxService.attachToNetworkTargetGroup(targetGroup);

    // ===== WAF v2 (Opcional) =====
    const webAcl = new wafv2.CfnWebACL(this, 'WebACL', {
      name: `${projectName}-web-acl`,
      scope: 'REGIONAL',
      defaultAction: { allow: {} },
      rules: [
        {
          name: 'RateLimitRule',
          priority: 1,
          action: { block: {} },
          statement: {
            rateBasedStatement: {
              limit: 1000,
              aggregateKeyType: 'IP',
            },
          },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'RateLimitRule',
          },
        },
        {
          name: 'AWSManagedRulesCommonRuleSet',
          priority: 2,
          overrideAction: { none: {} },
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesCommonRuleSet',
            },
          },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'CommonRuleSetMetric',
          },
        },
      ],
      visibilityConfig: {
        sampledRequestsEnabled: true,
        cloudWatchMetricsEnabled: true,
        metricName: `${projectName}WebAclMetric`,
      },
    });

    // ===== CloudWatch Dashboard =====
    const dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
      dashboardName: `${projectName}-dashboard-${environment}`,
    });

    // NLB Metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Network Load Balancer Metrics',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/NetworkELB',
            metricName: 'ActiveFlowCount',
            dimensionsMap: {
              LoadBalancer: nlb.loadBalancerFullName,
            },
            statistic: 'Average',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/NetworkELB',
            metricName: 'HealthyHostCount',
            dimensionsMap: {
              TargetGroup: targetGroup.targetGroupFullName,
              LoadBalancer: nlb.loadBalancerFullName,
            },
            statistic: 'Average',
          }),
        ],
        width: 12,
      })
    );

    // ECS Service Metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS Services Metrics',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'CPUUtilization',
            dimensionsMap: {
              ClusterName: cluster.clusterName,
              ServiceName: apiService.serviceName,
            },
            statistic: 'Average',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'CPUUtilization',
            dimensionsMap: {
              ClusterName: cluster.clusterName,
              ServiceName: nginxService.serviceName,
            },
            statistic: 'Average',
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: {
              ClusterName: cluster.clusterName,
              ServiceName: apiService.serviceName,
            },
            statistic: 'Average',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: {
              ClusterName: cluster.clusterName,
              ServiceName: nginxService.serviceName,
            },
            statistic: 'Average',
          }),
        ],
        width: 12,
      })
    );

    // ===== Outputs =====
    new cdk.CfnOutput(this, 'VpcId', {
      value: vpc.vpcId,
      description: 'VPC ID',
      exportName: `${projectName}-vpc-id`,
    });

    new cdk.CfnOutput(this, 'ClusterName', {
      value: cluster.clusterName,
      description: 'ECS Cluster Name',
      exportName: `${projectName}-cluster-name`,
    });

    new cdk.CfnOutput(this, 'NlbDnsName', {
      value: nlb.loadBalancerDnsName,
      description: 'Network Load Balancer DNS Name',
      exportName: `${projectName}-nlb-dns`,
    });

    new cdk.CfnOutput(this, 'ApiRepositoryUri', {
      value: apiRepository.repositoryUri,
      description: 'API ECR Repository URI',
      exportName: `${projectName}-api-repo-uri`,
    });

    new cdk.CfnOutput(this, 'NginxRepositoryUri', {
      value: nginxRepository.repositoryUri,
      description: 'Nginx ECR Repository URI',
      exportName: `${projectName}-nginx-repo-uri`,
    });

    new cdk.CfnOutput(this, 'ServiceDiscoveryNamespace', {
      value: namespace.namespaceName,
      description: 'Service Discovery Namespace',
      exportName: `${projectName}-service-discovery`,
    });

    new cdk.CfnOutput(this, 'ApiServiceName', {
      value: apiService.serviceName,
      description: 'API Service Name',
      exportName: `${projectName}-api-service-name`,
    });

    new cdk.CfnOutput(this, 'NginxServiceName', {
      value: nginxService.serviceName,
      description: 'Nginx Service Name',
      exportName: `${projectName}-nginx-service-name`,
    });
  }
}
