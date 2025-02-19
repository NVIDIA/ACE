#!/bin/bash


echo "Setup TOKKIO API -- Start"

echo 'redis-timeseries:
  storageClaims:
    data:
      spec:
        resources:
          requests:
            storage: 10Gi
redis:
  storageClaims:
    data:
      spec:
        resources:
          requests:
            storage: 1Gi
vms:
  storageClaims:
    local-storage:
      spec:
        resources:
          requests:
            storage: 1Gi
  configs:
    vst_config.json:
      network:
        twilio_account_sid: ${TWILIO_ACCOUNT_SID}
        twilio_auth_token: ${TWILIO_AUTH_TOKEN}
        use_twilio_stun_turn: ${USE_TWILIO_TURN_SERVER}
        static_turnurl_list:
        - "${TURNURL_CONN_STRING}"
        reverse_proxy_server_address: ${RP_INSTANCE_IP}:100
        use_reverse_proxy: ${USE_REVERSE_PROXY}
tokkio-ingress-mgr:
  enableStarFleetStg: ${ENABLE_IDP_AUTH}
mlops-data-collector:
  applicationSpecs:
    deployment:
      containers:
        tokkio-mlops-data-collector:
          env:
          - name: MONGO_HOSTNAME
            value: mongodb-mongodb-svc
          - name: MONGO_PORT
            value: "27017"
          - name: MONGO_DB_NAME
            value: ml_ops
          - name: REDIS_TIMESERIES_HOSTNAME
            value: redis-timeseries-redis-timeseries-svc
          - name: REDIS_TIMESERIES_PORT
            value: "6379"
          - name: REDIS_HOSTNAME
            value: redis-redis-svc
          - name: REDIS_PORT
            value: "6379"
          - name: EMDAT_HOSTNAME
            value: occupancy-alerts-api-app-svc
          - name: EMDAT_PORT
            value: "5000"
          - name: VMS_HOSTNAME
            value: vms-vms-svc
          - name: VMS_PORT
            value: "30000"
          - name: PACKAGE_PREFIX
            value: ${MLOPS_ENV}
        tokkio-mlops-data-uploader:
          env:
          - name: AWS_ACCESS_KEY_ID
            valueFrom:
              secretKeyRef:
                key: AWS_ACCESS_KEY_ID
                name: mlops-uploader-secret
                optional: true
          - name: AWS_SECRET_ACCESS_KEY
            valueFrom:
              secretKeyRef:
                key: AWS_SECRET_ACCESS_KEY
                name: mlops-uploader-secret
                optional: true
          - name: RCLONE_S3_REGION
            value: ${MLOPS_S3_REGION}
          - name: RCLONE_S3_ENDPOINT
            value: ""
          - name: DATA_STORE
            value: aws
          - name: BUCKET_NAME
            value: ${MLOPS_S3_BUCKET}
          - name: BW_LIMIT
            value: 10M' | envsubst > /tmp/ucf-tokkio-audio-video-app.yml

#Resetting any previous values.
cat /dev/null > /tmp/api-override-values.yaml

if [[ -n ${BOT_CONFIG_NAME} ]]; then
cat << EOF >> /tmp/api-override-values.yaml
botmaker-dialog-manager:
  botConfigName: ${BOT_CONFIG_NAME}
EOF
fi

if [[ -n ${CONTEXT_GENERAL_SEARCH} ]]; then
#split Pipe separated values
cat << EOF >> /tmp/api-override-values.yaml
botmaker-general-search:
  fmParameters:
    context_search:
EOF
for ctx in ${CONTEXT_GENERAL_SEARCH//|/ }
do
    echo "    - $ctx" >> /tmp/api-override-values.yaml
done

fi



helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --cleanup-on-fail \
  --reset-values \
  --create-namespace \
  --namespace "${API_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  --values /tmp/ucf-tokkio-audio-video-app.yml \
  --values /tmp/api-override-values.yaml \
  tokkio-app \
  "${TOKKIO_API_CHART_URL}"

echo "Setup TOKKIO API -- End"