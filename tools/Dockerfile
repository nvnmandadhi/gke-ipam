FROM cgr.dev/chainguard/google-cloud-sdk:latest

USER root

ENV PLATFORM=amd64 \
    TOFU_VERSION=1.6.1 \
    TOFU_DOWNLOAD_URL=https://github.com/opentofu/opentofu/releases/download \
    GCLOUD_SDK_PATH=/usr/share/google-cloud-sdk


RUN apk update && \
    apk add curl git wget make

RUN curl -LO ${TOFU_DOWNLOAD_URL}/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${PLATFORM}.apk && \
    apk add --allow-untrusted tofu_${TOFU_VERSION}_${PLATFORM}.apk && \
    chmod +x -R /usr/bin