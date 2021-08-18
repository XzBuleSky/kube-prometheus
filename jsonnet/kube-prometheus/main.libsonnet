local alertmanager = import './components/alertmanager.libsonnet';
local blackboxExporter = import './components/blackbox-exporter.libsonnet';
local grafana = import './components/grafana.libsonnet';
local kubernetesControlPlane = import './components/k8s-control-plane.libsonnet';
local kubeStateMetrics = import './components/kube-state-metrics.libsonnet';
local customMixin = import './components/mixin/custom.libsonnet';
local nodeExporter = import './components/node-exporter.libsonnet';
local prometheusAdapter = import './components/prometheus-adapter.libsonnet';
local prometheusOperator = import './components/prometheus-operator.libsonnet';
local prometheus = import './components/prometheus.libsonnet';

local platformPatch = import './platforms/platforms.libsonnet';

local utils = import './lib/utils.libsonnet';

{
  // using `values` as this is similar to helm
  values:: {
    common: {
      namespace: 'default',
      platform: null,
      ruleLabels: {
        role: 'alert-rules',
        prometheus: $.values.prometheus.name,
      },
      // to allow automatic upgrades of components, we store versions in autogenerated `versions.json` file and import it here
      versions: {
        alertmanager: error 'must provide version',
        blackboxExporter: error 'must provide version',
        grafana: error 'must provide version',
        kubeStateMetrics: error 'must provide version',
        nodeExporter: error 'must provide version',
        prometheus: error 'must provide version',
        prometheusAdapter: error 'must provide version',
        prometheusOperator: error 'must provide version',
        kubeRbacProxy: error 'must provide version',
        configmapReload: error 'must provide version',
      } + (import 'versions.json'),
      images: {
        alertmanager: 'quay.io/prometheus/alertmanager:v' + $.values.common.versions.alertmanager,
        blackboxExporter: 'quay.io/prometheus/blackbox-exporter:v' + $.values.common.versions.blackboxExporter,
        grafana: 'grafana/grafana:v' + $.values.common.versions.grafana,
        kubeStateMetrics: 'k8s.gcr.io/kube-state-metrics/kube-state-metrics:v' + $.values.common.versions.kubeStateMetrics,
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.values.common.versions.nodeExporter,
        prometheus: 'quay.io/prometheus/prometheus:v' + $.values.common.versions.prometheus,
        prometheusAdapter: 'k8s.gcr.io/prometheus-adapter/prometheus-adapter:v' + $.values.common.versions.prometheusAdapter,
        prometheusOperator: 'quay.io/prometheus-operator/prometheus-operator:v' + $.values.common.versions.prometheusOperator,
        prometheusOperatorReloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + $.values.common.versions.prometheusOperator,
        kubeRbacProxy: 'quay.io/brancz/kube-rbac-proxy:v' + $.values.common.versions.kubeRbacProxy,
        configmapReload: 'jimmidyson/configmap-reload:v' + $.values.common.versions.configmapReload,
      },
    },
    alertmanager: {
      name: 'main',
      namespace: $.values.common.namespace,
      version: $.values.common.versions.alertmanager,
      image: $.values.common.images.alertmanager,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
    blackboxExporter: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.blackboxExporter,
      image: $.values.common.images.blackboxExporter,
      kubeRbacProxyImage: $.values.common.images.kubeRbacProxy,
      configmapReloaderImage: $.values.common.images.configmapReload,
    },
    grafana: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.grafana,
      image: $.values.common.images.grafana,
      prometheusName: $.values.prometheus.name,
      // TODO(paulfantom) This should be done by iterating over all objects and looking for object.mixin.grafanaDashboards
      dashboards: $.nodeExporter.mixin.grafanaDashboards + $.prometheus.mixin.grafanaDashboards + $.kubernetesControlPlane.mixin.grafanaDashboards + $.alertmanager.mixin.grafanaDashboards,
    },
    kubeStateMetrics: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.kubeStateMetrics,
      image: $.values.common.images.kubeStateMetrics,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
      kubeRbacProxyImage: $.values.common.images.kubeRbacProxy,
    },
    nodeExporter: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.nodeExporter,
      image: $.values.common.images.nodeExporter,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
      kubeRbacProxyImage: $.values.common.images.kubeRbacProxy,
    },
    prometheus: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.prometheus,
      image: $.values.common.images.prometheus,
      name: 'k8s',
      alertmanagerName: $.values.alertmanager.name,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
    prometheusAdapter: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.prometheusAdapter,
      image: $.values.common.images.prometheusAdapter,
      prometheusURL: 'http://prometheus-' + $.values.prometheus.name + '.' + $.values.common.namespace + '.svc.cluster.local:9090/',
      hostNetwork: false,
      rangeIntervals+: {
        kubelet: utils.rangeInterval($.kubernetesControlPlane.serviceMonitorKubelet.spec.endpoints[0].interval),
        nodeExporter: utils.rangeInterval($.nodeExporter.serviceMonitor.spec.endpoints[0].interval),
      },
    },
    prometheusOperator: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.prometheusOperator,
      image: $.values.common.images.prometheusOperator,
      configReloaderImage: $.values.common.images.prometheusOperatorReloader,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
      kubeRbacProxyImage: $.values.common.images.kubeRbacProxy,
    },
    kubernetesControlPlane: {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
  },

  alertmanager: alertmanager($.values.alertmanager),
  blackboxExporter: blackboxExporter($.values.blackboxExporter),
  grafana: grafana($.values.grafana),
  kubeStateMetrics: kubeStateMetrics($.values.kubeStateMetrics),
  nodeExporter: nodeExporter($.values.nodeExporter),
  prometheus: prometheus($.values.prometheus),
  prometheusAdapter: prometheusAdapter($.values.prometheusAdapter),
  prometheusOperator: prometheusOperator($.values.prometheusOperator),
  kubernetesControlPlane: kubernetesControlPlane($.values.kubernetesControlPlane),
  kubePrometheus: customMixin(
    {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    }
  ) + {
    namespace: {
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: {
        name: $.values.common.namespace,
      },
    },
  },
} + platformPatch
