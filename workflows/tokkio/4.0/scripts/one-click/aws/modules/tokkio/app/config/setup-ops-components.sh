#!/bin/bash


echo "Setup OPS COMPONENTS -- Start"

echo "updating fs.inotify.max_user_instances"
echo "fs.inotify.max_user_instances=8192" >> /etc/sysctl.conf
sysctl --system


echo 'fluent-bit:
  enable: true
  config:
    service: |
      [SERVICE]
          Daemon Off
          Flush {{ .Values.flush }}
          Log_Level {{ .Values.logLevel }}
          Parsers_File parsers.conf
          Parsers_File custom_parsers.conf
          HTTP_Server On
          HTTP_Listen 0.0.0.0
          HTTP_Port {{ .Values.metricsPort }}
          Health_Check On
 
    ## https://docs.fluentbit.io/manual/pipeline/inputs
    inputs: |
      [INPUT]
          Name tail
          Path /var/log/containers/*.log
          multiline.parser docker, cri
          Tag kube.*
          Mem_Buf_Limit 5MB
          Skip_Long_Lines On
 
      [INPUT]
          Name systemd
          Tag host.*
          Systemd_Filter _SYSTEMD_UNIT=kubelet.service
          Read_From_Tail On
 
    ## https://docs.fluentbit.io/manual/pipeline/filters
    filters: |
      [FILTER]
          Name kubernetes
          Match kube.*
          Merge_Log On
          Keep_Log Off
          K8S-Logging.Parser On
          K8S-Logging.Exclude On
 
      [FILTER]
          Name grep
          Match kube.*
          Exclude kubernetes_container_name fluent-bit
 
    ## https://docs.fluentbit.io/manual/pipeline/outputs
    outputs: |
      [OUTPUT]
          Name es
          Match kube.*
          Host ${OPS_ES_CLUSTER_NAME}-master-headless
          # Logstash_Format On
          # Logstash_DateFormat %Y-%m-%d
          Index k8s-logs
          # Logstash_Prefix k8s
          Replace_Dots On
          # Type _doc
          Retry_Limit False
          Trace_Error On
 
      [OUTPUT]
          Name es
          Match host.*
          Host ${OPS_ES_CLUSTER_NAME}-master-headless
          Logstash_Format On
          Logstash_Prefix node
          Replace_Dots On
          # Type _doc
          Retry_Limit False
          # Trace_Error On
 
      # [OUTPUT]
      #     Name stdout
      #     Match kube.*
      #     Format json
      #     Json_date_key timestamp
      #     Json_date_format iso8601
 
    ## https://docs.fluentbit.io/manual/administration/configuring-fluent-bit/classic-mode/upstream-servers
    ## This configuration is deprecated, please use `extraFiles` instead.
    upstream: {}
 
    ## https://docs.fluentbit.io/manual/pipeline/parsers
    customParsers: |
      [PARSER]
          Name docker_no_time
          Format json
          Time_Keep Off
          Time_Key time
          Time_Format %Y-%m-%dT%H:%M:%S.%L' | envsubst > /tmp/tokkio-fluent-bit-override-values.yaml

echo 'elasticsearch:
  clusterName: ${OPS_ES_CLUSTER_NAME}
  volumeClaimTemplate:
    storageClassName: mdx-local-path
kibana:
  elasticsearchHosts: http://${OPS_ES_CLUSTER_NAME}-master-headless:9200
  service:
    nodePort: "31565"
ingress:
  enabled: false' | envsubst > /tmp/tokkio-logging-es-override-values.yaml

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --reset-values \
  --create-namespace \
  --namespace "${OPS_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  tokkio-ingress-controller \
  "${INGRESS_CONTROLLER_CHART_URL}"

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --reset-values \
  --create-namespace \
  --namespace "${OPS_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  --values /tmp/tokkio-logging-es-override-values.yaml \
  tokkio-logging-es \
  "${LOGGING_ELASTIC_KIBANA_CHART_URL}"

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --reset-values \
  --create-namespace \
  --namespace "${OPS_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  mdx-kube-prometheus-stack \
  "${PROMETHEUS_STACK_CHART_URL}"

cat << EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: tokkio-logging-es-logging-stack-elastic-kibana
  namespace: ${OPS_NS}
spec:
  rules:
  - host: ${ELASTIC_DOMAIN}
    http:
      paths:
      - backend:
          service:
            name: ${OPS_ES_CLUSTER_NAME}-master
            port:
              number: 9200
        path: /
        pathType: Prefix
  - host: ${KIBANA_DOMAIN}
    http:
      paths:
      - backend:
          service:
            name: tokkio-logging-es-kibana
            port:
              number: 5601
        path: /
        pathType: Prefix
  - host: ${GRAFANA_DOMAIN}
    http:
      paths:
      - backend:
          service:
            name: mdx-kube-prometheus-stack-grafana
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}

EOF

# moving to last to make fluentbit the last one to install
echo "sleep for 180 sec" && sleep 180 
helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --reset-values \
  --create-namespace \
  --namespace "${OPS_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  --values /tmp/tokkio-fluent-bit-override-values.yaml \
  tokkio-fluent-bit \
  "${LOGGING_FLUENTBIT_CHART_URL}"


# As setting index.number_of_replicas = 0 on es cluster as we have only single pod and cluster status fails on node reboot for es-master pod
cat <<EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: script-config
  namespace: ${OPS_NS}
data:
  update_es_replicas.sh: |
    set -x
    while true; do
      date
      if [ "\$(curl -s -o /dev/null -w '%{http_code}' http://tokkio-logging-es-cluster-master:9200/_cluster/health)" -ne 200 ]; then
        echo "setting index.number_of_replicas to 0"
        curl "tokkio-logging-es-cluster-master-headless:9200/_settings/index.number_of_replicas?pretty";
        curl -X PUT "tokkio-logging-es-cluster-master-headless:9200/_settings" -H "Content-Type: application/json" -d '{"index":{"number_of_replicas":0}}'
        echo "showing updated index.number_of_replicas"
        curl "tokkio-logging-es-cluster-master-headless:9200/_settings/index.number_of_replicas?pretty"
      else
        echo "response is \$(curl -s -o /dev/null -w '%{http_code}' http://tokkio-logging-es-cluster-master:9200/_cluster/health)"
      fi
      sleep 10
    done
EOF


cat << EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: es-replicas-update-deployment
  labels:
     app: es-replicas-update
  namespace: ${OPS_NS}
spec:
    replicas: 1
    selector:
      matchLabels:
        app: es-replicas-update
    template:
      metadata:
        labels:
          app: es-replicas-update
      spec:
        containers:
        - name: curl-commands
          image: giantswarm/tiny-tools
          command: ["/bin/sh", "-c"]
          args: ["/scripts/update_es_replicas.sh"]
          resources:
            requests:
              memory: "100Mi"
              cpu: "200m"
            limits:
              memory: "200Mi"
              cpu: "1"
          volumeMounts:
            - name: script-volume
              mountPath: /scripts
        volumes:
          - name: script-volume
            configMap:
              name: script-config
              defaultMode: 0777
EOF

echo "Setup OPS COMPONENTS -- End"