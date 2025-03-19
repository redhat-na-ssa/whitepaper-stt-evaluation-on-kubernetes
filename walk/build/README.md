# Build

### Whisper on OpenShift with a UBI container

This tests Whisper in a UBI container on OpenShift

```sh
APP_NAME=whisper
APP_LABEL="app.kubernetes.io/part-of=${APP_NAME}"

oc new-project "${APP_NAME}"

# configure new build config
oc new-build \
  -n "${NAMESPACE}" \
  --name "${APP_NAME}" \
  -l "${APP_LABEL}" \
  --strategy docker \
  --binary

# patch image stream to resolve local
oc patch imagestream \
  "${APP_NAME}" \
   --type=merge \
  --patch '{"spec":{"lookupPolicy":{"local":true}}}'

# start build from local folder
oc start-build \
  -n "${NAMESPACE}" \
  "${APP_NAME}" \
  --follow \
  --from-dir openai-whisper/ubi/platform

# run a container on openshift like docker
oc run \
  -it --rm \
  --image whisper \
  --restart=Never \
  whisper -- /bin/bash
```

