ARG BASE_IMAGE=nvcr.io/nvidia/tritonserver:23.07-py3
ARG S6_VERSION=v3.2.0.2


FROM ${BASE_IMAGE}

ARG S6_VERSION
ARG DEBIAN_FRONTEND=noninteractive

# Install latest s6-overlay and runtime dependencies for frontend app.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    python3-pip \
    xz-utils \
    tini \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

RUN python3 -m pip install --no-cache-dir \
    fastapi \
    pydantic \
    python-dotenv \
    tritonclient[grpc] \
    uvicorn[standard] \
    pillow \
    opencv-python-headless \
    numpy==1.26.4 \
    prometheus-client \
    httpx \
    orjson

ENV PYTHONUNBUFFERED=1

WORKDIR /

ENTRYPOINT ["/init"]
