# FastAPI + Triton Serving Template

This template builds a serving container that combines:
- Triton Inference Server (from your minimal base image)
- FastAPI frontend wrapper (uvicorn)
- s6-overlay process supervision with s6-rc service layout

## Base Image

The template Dockerfile uses:
- `lokeshkurre/tritonserver:24.09-slim`

Update the first line in `Dockerfile` if you want a different Triton base image/tag.

## Installed Python Packages

- fastapi
- pydantic
- python-dotenv
- tritonclient[grpc,http]
- uvicorn
- pillow
- opencv-python-headless
- numpy==1.26.4
- prometheus-client
- httpx

## Folder Structure

```text
template-serving/
  Dockerfile
  rootfs/
    app/
      __init__.py
      __main__.py
    model_repository/
    etc/
      s6-overlay/
        s6-rc.d/
          front-end/
          tritonserver/
          user/contents.d/
```

## Services

- `tritonserver`
  - starts Triton with model repository and configurable ports
- `front-end`
  - starts FastAPI via uvicorn using app factory mode
  - depends on `tritonserver` in s6-rc

## Default Ports

- FastAPI: `8080`
- Triton HTTP: `9001`
- Triton gRPC: `9002`
- Triton Metrics: `9090`

## Environment Variables

- `FRONTEND_HOST` (default `0.0.0.0`)
- `FRONTEND_PORT` (default `8080`)
- `TRITON_MODEL_REPOSITORY` (default `/model_repository`)
- `TRITON_HTTP_PORT` (default `9001`)
- `TRITON_GRPC_PORT` (default `9002`)
- `TRITON_METRICS_PORT` (default `9090`)

## Build

From repository root:

```bash
make build-fastapi-wrapper
```

Or directly:

```bash
docker build -t lokeshkurre/tritonserver-fastapi:24.09-slim -f template-serving/Dockerfile template-serving
```

## Run

From repository root:

```bash
make run-fastapi-wrapper
```

Or directly:

```bash
docker run --rm -it \
  -p 8080:8080 -p 9001:9001 -p 9002:9002 -p 9090:9090 \
  -v "$(pwd)/template-serving/rootfs/model_repository:/model_repository" \
  lokeshkurre/tritonserver-fastapi:24.09-slim
```

## Health Checks

- FastAPI: `GET /health` on port `8080`
- Triton: `GET /v2/health/ready` on port `9001`

## Notes

- This is a placeholder/template scaffold for serving workloads.
- Add real models under `rootfs/model_repository/` or mount an external repository.
- Extend `rootfs/app/` to implement production API logic and Triton client calls.
