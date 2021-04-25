local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet'; 
local pvc = k.core.v1.persistentVolumeClaim;
local deployment = k.apps.v1beta2.deployment;
local container = k.apps.v1beta2.deployment.mixin.spec.template.spec.containersType;
local volume = k.apps.v1beta2.deployment.mixin.spec.template.spec.volumesType;
local containerVolumeMount = container.volumeMountsType;

local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-kops.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-kops-coredns.libsonnet') +
  // Uncomment the following imports to enable its patches
  (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  {
    _config+:: {

      namespace: 'monitoring',
      cpuThrottlingPercent: 60,

      prometheus+:: {
        namespaces+: ['ambassador'],
      },
      grafana+:: {
        datasources: [
            {
                name: 'Prometheus',
                type: 'prometheus',
                access: 'proxy',
                orgId: 1,
                url: 'http://' + $._config.prometheus.serviceName + '.' + $._config.namespace + '.svc:9090',
                version: 1,
                editable: false,
            }
        ],
        config: { // http://docs.grafana.org/installation/configuration/
            sections: {
                'security': {
                    admin_user: 'admin',
                    admin_password: 'admin',
                },
            },
        },
      },
    },

    grafanaDashboards+:: {
      'ambassador.json': (import 'ambassador.json'),
    },

    prometheusAlerts+:: {
        groups+: [
        {
            name: 'ambassador-5xx',
            rules: [
              {
                alert: 'Ambassador5XXErrors',
                expr: 'rate(envoy_http_downstream_rq_xx{envoy_response_code_class="5"}[5m]) > 0',
                'for': '15m',
                labels: {
                    severity: 'critical',
                },
                annotations: {
                    message: 'There are some 5xx errors in last 15 minutes',
                    summary: 'Ambassador 5xx Errors',
                },
              },
            ],
        },
        ],
    },
    
    local tmpVolumeName = 'tmpfs',
    local tmpVolume = volume.fromEmptyDir(tmpVolumeName),
    local tmpVolumeMount = containerVolumeMount.new(tmpVolumeName, '/tmp'),

    prometheusAdapter+::{
        deployment+: {
            metadata+:{
                labels+:{
                    'app': 'prometheus-adapter',
                    'version': $._config.versions.prometheusAdapter,
                },
            },
            spec+:{
                template+:{
                    metadata+:{
                        labels+:{
                            'app': 'prometheus-adapter',
                            'version': $._config.versions.prometheusAdapter,
                        },
                    },
                },
            },
        },
    },

    grafana+::{
        deployment+: {
            spec+:{
                template+:{
                    metadata+:{
                        labels+:{
                            'app': 'grafana',
                            'version': $._config.versions.grafana,
                        },
                    },
                    spec+:{
                        volumes+:
                            [
                                tmpVolume,
                            ],
                        containers:
                            std.map(
                                function(c)
                                    if c.name == 'grafana' then
                                        c {
                                            volumeMounts+: [
                                                tmpVolumeMount,
                                            ],
                                        }
                                    else
                                    c,
                                super.containers,
                            ),
                    },
                },
            },
        },
    },

    prometheusOperator+::{
        deployment+: {
            spec+:{
                template+:{
                    metadata+:{
                        labels+:{
                            'app': 'prometheus-operator',
                            'version': $._config.versions.prometheusOperator,
                        },
                    },
                },
            },
        },
    },

    kubeStateMetrics+::{
        deployment+: {
            spec+:{
                template+:{
                    metadata+:{
                        labels:{
                            'app': 'kube-state-metrics',
                            'version': $._config.versions.kubeStateMetrics,
                            'app.kubernetes.io/name': 'kube-state-metrics',
                            'app.kubernetes.io/version': $._config.versions.kubeStateMetrics,
                        },
                    },
                    spec+: {
                        securityContext: {
                            runAsUser: 65532,
                            runAsGroup: 65532,
                            runAsNonRoot: true,
                        },
                    },
                },
            },
        },
    },
    
    prometheus+:: {
        local p = self,
        service:
            local service = k.core.v1.service;
            local servicePort = k.core.v1.service.mixin.spec.portsType;

            local prometheusPort = servicePort.newNamed('http-9090', 9090, 'http-9090');

            service.new('prometheus-' + p.name, { app: 'prometheus', prometheus: p.name }, prometheusPort) +
            service.mixin.spec.withSessionAffinity('ClientIP') +
            service.mixin.metadata.withNamespace(p.namespace) +
            service.mixin.metadata.withLabels({ prometheus: p.name }),
        serviceMonitor:
        {
            apiVersion: 'monitoring.coreos.com/v1',
            kind: 'ServiceMonitor',
            metadata: {
                name: 'prometheus',
                namespace: p.namespace,
                labels: {
                    'k8s-app': 'prometheus',
                },
            },
            spec: {
                selector: {
                    matchLabels: {
                        prometheus: p.name,
                    },
                },
                endpoints: [
                    {
                        port: 'http-9090',
                        interval: '30s',
                    },
                ],
            },
        },
        serviceMonitorKubelet:
        {
            apiVersion: 'monitoring.coreos.com/v1',
            kind: 'ServiceMonitor',
            metadata: {
            name: 'kubelet',
            namespace: p.namespace,
            labels: {
                'k8s-app': 'kubelet',
            },
            },
            spec: {
            jobLabel: 'k8s-app',
            endpoints: [
                {
                port: 'http-metrics',
                scheme: 'http',
                interval: '30s',
                honorLabels: true,
                tlsConfig: {
                    insecureSkipVerify: true,
                },
                bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
                metricRelabelings: (import 'kube-prometheus/dropping-deprecated-metrics-relabelings.libsonnet'),
                relabelings: [
                    {
                    sourceLabels: ['__metrics_path__'],
                    targetLabel: 'metrics_path',
                    },
                ],
                },
                {
                port: 'http-metrics',
                scheme: 'http',
                path: '/metrics/cadvisor',
                interval: '30s',
                honorLabels: true,
                tlsConfig: {
                    insecureSkipVerify: true,
                },
                bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
                relabelings: [
                    {
                    sourceLabels: ['__metrics_path__'],
                    targetLabel: 'metrics_path',
                    },
                ],
                metricRelabelings: [
                    // Drop a bunch of metrics which are disabled but still sent, see
                    // https://github.com/google/cadvisor/issues/1925.
                    {
                    sourceLabels: ['__name__'],
                    regex: 'container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)',
                    action: 'drop',
                    },
                ],
                },
            ],
            selector: {
                matchLabels: {
                'k8s-app': 'kubelet',
                },
            },
            namespaceSelector: {
                matchNames: [
                'kube-system',
                ],
            },
            },
        },
        prometheus+: {
            spec+: {
                
                alerting: {
                    alertmanagers: [
                    {
                        namespace: p.namespace,
                        name: p.alertmanagerName,
                        port: 'http-9093',
                    },
                    ],
                },  
                podMetadata: {
                    labels:{
                        'version': $._config.versions.prometheus,
                    },
                },
                portName: 'http-9090',
                retention: '1y',
                storage: {  
                    volumeClaimTemplate:  
                        pvc.new() +  
                        pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                        pvc.mixin.spec.resources.withRequests({ storage: '500Gi' }) +
                        pvc.mixin.spec.withStorageClassName('geophy-retain-gp2'),
                },  // storage
            },  // spec
        },  // prometheus
    },

    alertmanager+:: {

        service:
            local service = k.core.v1.service;
            local servicePort = k.core.v1.service.mixin.spec.portsType;

            local alertmanagerPort = servicePort.newNamed('http-9093', 9093, 'http-9093');

            service.new('alertmanager-' + $._config.alertmanager.name, { app: 'alertmanager', alertmanager: $._config.alertmanager.name }, alertmanagerPort) +
            service.mixin.spec.withSessionAffinity('ClientIP') +
            service.mixin.metadata.withNamespace($._config.namespace) +
            service.mixin.metadata.withLabels({ alertmanager: $._config.alertmanager.name }),

        serviceMonitor:
        {
            apiVersion: 'monitoring.coreos.com/v1',
            kind: 'ServiceMonitor',
            metadata: {
                name: 'alertmanager',
                namespace: $._config.namespace,
                labels: {
                    'k8s-app': 'alertmanager',
                },
            },
            spec: {
                selector: {
                    matchLabels: {
                        alertmanager: $._config.alertmanager.name,
                    },
                },
                endpoints: [
                    {
                        port: 'http-9093',
                        interval: '30s',
                    },
                ],
            },
        },

        alertmanager+:
        {
            spec: {
                replicas: 1,
                version: $._config.versions.alertmanager,
                baseImage: $._config.imageRepos.alertmanager,
                podMetadata: {
                    labels:{
                        'version': $._config.versions.alertmanager,
                    },
                    annotations:{
                        'sidecar.istio.io/rewriteAppHTTPProbers': 'true',
                    },
                },
                portName: 'http-9093',
                serviceAccountName: 'alertmanager-' + $._config.alertmanager.name,
                securityContext: {
                    runAsUser: 1000,
                    runAsNonRoot: true,
                    fsGroup: 2000,
                },
            },
        },
    },
  };


{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
