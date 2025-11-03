# Kubernetes Monitoring and Alerting Setup

## Current Status ✅

✅ **Completed:**
- Spring Boot application running on Kubernetes (demo-app namespace)
- Prometheus installed via Helm (monitoring namespace)
- Grafana installed with admin access
- Basic cluster monitoring active

🔄 **Next Steps:**
- Configure AlertManager for notifications
- Create CPU usage alerts (>80% for 1 minute)  
- Set up email/Slack notifications
- Load test with JMeter to trigger alerts

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Prometheus    │    │    Grafana      │
│  (demo-app ns)  │◄───│ (monitoring ns) │◄───│ (monitoring ns) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  AlertManager   │───►│ Notifications   │
                       │ (monitoring ns) │    │ Email/Slack/Web │
                       └─────────────────┘    └─────────────────┘
```

## Step 1: Configure AlertManager

AlertManager handles alert routing, grouping, and notifications from Prometheus.

### Check Current AlertManager Status
```bash
kubectl get pods -n monitoring | grep alertmanager
kubectl get svc -n monitoring | grep alertmanager
```

### Configure AlertManager for Email/Slack Notifications
```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'your-email@gmail.com'
      smtp_auth_username: 'your-email@gmail.com'
      smtp_auth_password: 'your-app-password'
    
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          severity: critical
        receiver: email-notifications
      - match:
          severity: warning  
        receiver: slack-notifications
    
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://example.com/webhook'
    
    - name: email-notifications
      email_configs:
      - to: 'alert@company.com'
        subject: '[CRITICAL] Kubernetes Alert'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
    
    - name: slack-notifications
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

## Step 2: Create CPU Usage Alert Rules

### CPU Alert Rules Configuration
```yaml
# cpu-alert-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cpu-usage-alerts
  namespace: monitoring
  labels:
    app: prometheus
spec:
  groups:
  - name: cpu.rules
    rules:
    - alert: HighPodCPUUsage
      expr: (sum(rate(container_cpu_usage_seconds_total{pod!=""}[5m])) by (pod, namespace) / sum(container_spec_cpu_quota{pod!=""}/container_spec_cpu_period{pod!=""}) by (pod, namespace)) * 100 > 80
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} in {{ $labels.namespace }} has high CPU usage"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been using more than 80% CPU for more than 1 minute."
    
    - alert: HighNodeCPUUsage
      expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "Node {{ $labels.instance }} has high CPU usage"
        description: "Node {{ $labels.instance }} has been using more than 80% CPU for more than 1 minute."
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 0m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently."
```

## Step 3: Load Testing with JMeter

### Install JMeter
```bash
# On macOS
brew install jmeter

# Or download from https://jmeter.apache.org/download_jmeter.cgi
```

### JMeter Test Plan for CPU Load
```xml
<!-- cpu-load-test.jmx -->
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="CPU Load Test">
      <elementProp name="TestPlan.arguments" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables"/>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Load Test">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControllerGui" testclass="LoopController" testname="Loop Controller">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">100</stringProp>
        <stringProp name="ThreadGroup.ramp_time">30</stringProp>
        <longProp name="ThreadGroup.start_time">1</longProp>
        <longProp name="ThreadGroup.end_time">1</longProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
        <stringProp name="ThreadGroup.duration">300</stringProp>
        <stringProp name="ThreadGroup.delay"></stringProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="HTTP Request">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" testname="User Defined Variables">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.domain">localhost</stringProp>
          <stringProp name="HTTPSampler.port">8080</stringProp>
          <stringProp name="HTTPSampler.protocol">http</stringProp>
          <stringProp name="HTTPSampler.contentEncoding"></stringProp>
          <stringProp name="HTTPSampler.path">/</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
          <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
          <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
          <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
          <stringProp name="HTTPSampler.connect_timeout"></stringProp>
          <stringProp name="HTTPSampler.response_timeout"></stringProp>
        </HTTPSamplerProxy>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

## Step 4: Implementation Commands

Let's implement this monitoring and alerting setup step by step.

## Next Steps

1. **Check AlertManager Status**
2. **Configure Alert Rules for CPU Usage**
3. **Set up Notification Channels**
4. **Test with Load Generation**
5. **Verify Alert Delivery**

Ready to proceed with the implementation?