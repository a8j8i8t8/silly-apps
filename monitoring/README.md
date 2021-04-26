# Monitoring Silly Apps
Script in this uses manifests from repo [kube-prometheus](https://github.com/coreos/kube-prometheus).

This stack is meant for cluster monitoring, so it is pre-configured to collect metrics from all Kubernetes components. In addition to that it delivers a default set of dashboards and alerting rules. Many of the useful dashboards and alerts come from the [kubernetes-mixin project](https://github.com/kubernetes-monitoring/kubernetes-mixin).

I've created this automation to inculde following three things regarding Silly-Apps:
1. `ServiceMonitor` resource to scrape metrics directly from the `/metrics` endpoint of Ambassador Edge Stack
2. Prometheus alert for Ambassador GW 5XX errors
3. Grafana dashboard for [Ambassador](https://grafana.com/grafana/dashboards/13758)
## Deploy
Deploy Prometheus monitoring stack as below.
- Make sure you've running Kubernetes cluster
- Make sure your kube-context is pointing to correct Kubernetes cluster

```shell
$ git clone https://gitlab.com/a8j8i8t8/silly-apps.git
$ cd silly-apps/monitoring
$ kubectl create namespace monitoring
$ bash monitoring.sh
```
