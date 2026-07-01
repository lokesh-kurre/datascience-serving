FROM lokeshkurre/tritonserver:24.09-slim

ARG DEBIAN_FRONTEND=noninteractive

# Install latest s6-overlay and runtime dependencies for frontend app.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    python3-pip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

RUN python3 -m pip install --no-cache-dir \
    fastapi \
    pydantic \
    python-dotenv \
    tritonclient[grpc,http] \
    uvicorn \
    pillow \
    opencv-python-headless \
    numpy==1.26.4 \
    prometheus-client \
    httpx

COPY rootfs/ /

RUN find /etc/s6-overlay/ -type f -name run -exec chmod +x {} +

ENV PYTHONUNBUFFERED=1 \
    FRONTEND_HOST=0.0.0.0 \
    FRONTEND_PORT=8080 \
    TRITON_MODEL_REPOSITORY=/model_repository \
    TRITON_HTTP_PORT=9001 \
    TRITON_GRPC_PORT=9002 \
    TRITON_METRICS_PORT=9090

WORKDIR /

VOLUME ["/app", "/model_repository"]

EXPOSE 8080 9001 9002 9090

ENTRYPOINT ["/init"]
