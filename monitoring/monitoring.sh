#!/bin/bash
set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb 
go get github.com/brancz/gojsontoyaml
go get github.com/google/go-jsonnet/cmd/jsonnet
jb init
jb install github.com/coreos/kube-prometheus/jsonnet/kube-prometheus@release-0.7
# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# Download ambassador dashboard
rm -rf ambassador.json || true
wget -q https://grafana.com/api/dashboards/13758/revisions/1/download -O ambassador.json
# optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests "monitoring.jsonnet" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}

cp ambassador-serviceMonitor.yaml manifests/
rm -rf manifests/prometheus-kubeDnsPrometheusDiscoveryService.yaml
kubectl apply -f manifests/setup/
sleep 5s
kubectl apply -f manifests/