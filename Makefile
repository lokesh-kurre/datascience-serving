# Makefile for building minimal customized Triton Inference Server
# Uses Triton's compose.py to selectively copy backends from full image

# Triton container version/tag (e.g., 24.09, 24.10)
# Recommendation: 24.09 (stable, includes Python 3.10, PyTorch 2.5, TensorFlow 2.16, CUDA 12.6, cuDNN 9.4, TensorRT 10.4)
TRITON_TAG ?= 24.09

# Space-separated list of backends to include
# Available: python, dali, onnxruntime, tensorrt, pytorch, tensorflow, etc.
# Note: ensemble is a core backend (built into tritonserver binary) and is always included
BACKENDS ?= python dali onnxruntime tensorrt

# Space-separated list of repo agents to include (optional)
REPOAGENTS ?= 

# Enable GPU support (set to ON for GPU builds, OFF for CPU-only)
ENABLE_GPU ?= ON

# Build output directory
BUILD_DIR ?= build
OUTPUT_DIR ?= $(BUILD_DIR)/triton-minimal
DOCKERFILE_DIR ?= $(BUILD_DIR)/docker
DOCKERFILE_PATH := $(abspath $(DOCKERFILE_DIR))/Dockerfile.compose

# Triton source directory with compose.py
TRITON_SRC := extern/tritonserver
TRITON_BUILD_CONTEXT := $(abspath $(TRITON_SRC))

# Full Triton image to compose from
TRITON_FULL_IMAGE ?= nvcr.io/nvidia/tritonserver:$(TRITON_TAG)-py3

# Minimal base image (used as starting point for composed image)
TRITON_MIN_IMAGE ?= nvcr.io/nvidia/tritonserver:$(TRITON_TAG)-py3-min

# Output Docker image name
OUTPUT_IMAGE ?= lokeshkurre/tritonserver:$(TRITON_TAG)-slim

# FastAPI wrapper template build settings
WRAPPER_DIR ?= template-serving
WRAPPER_IMAGE ?= lokeshkurre/tritonserver-fastapi:$(TRITON_TAG)-slim

# Skip pulling latest images (use locally available)
SKIP_PULL ?= false

# Verbose output
VERBOSE ?= false

# Build flags construction
COMPOSE_FLAGS := --container-version $(TRITON_TAG)
COMPOSE_FLAGS += --work-dir $(abspath $(DOCKERFILE_DIR))

# Add backends
ifdef BACKENDS
	COMPOSE_FLAGS += $(foreach backend,$(BACKENDS),--backend $(backend))
endif

# Add repo agents if specified
ifdef REPOAGENTS
	COMPOSE_FLAGS += $(foreach ra,$(REPOAGENTS),--repoagent $(ra))
endif

# GPU flag
ifeq ($(ENABLE_GPU),ON)
	COMPOSE_FLAGS += --enable-gpu
	GPU_FLAG = GPU-enabled
else
	COMPOSE_FLAGS += --enable-cpu-only
	GPU_FLAG = CPU-only
endif

ifeq ($(SKIP_PULL),true)
	COMPOSE_FLAGS += --skip-pull
endif

ifeq ($(VERBOSE),true)
	COMPOSE_FLAGS += --verbose
endif

.PHONY: help build compose build-fastapi-wrapper run-fastapi-wrapper clean info

help:
	@echo "Triton Inference Server - Minimal Compose Build"
	@echo "================================================"
	@echo ""
	@echo "Uses compose.py to selectively extract backends from official Triton image"
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "Targets:"
	@echo "  make build              - Build minimal Triton Docker image"
	@echo "  make compose            - Generate Dockerfile (without building)"
	@echo "  make build-fastapi-wrapper - Build FastAPI + Triton wrapper image"
	@echo "  make run-fastapi-wrapper   - Run FastAPI + Triton wrapper image"
	@echo "  make clean              - Remove build artifacts"
	@echo "  make info               - Show build configuration"
	@echo ""
	@echo "Configuration Variables:"
	@echo "  TRITON_TAG              - Triton container tag (default: 24.09)"
	@echo "  BACKENDS                - Space-separated backends (default: python dali onnxruntime tensorrt)"
	@echo "                            (ensemble is a core backend, always included)"
	@echo "  ENABLE_GPU              - Enable GPU support (default: ON)"
	@echo "  REPOAGENTS              - Space-separated repo agents (optional)"
	@echo "  TRITON_FULL_IMAGE       - Full Triton image to compose from"
	@echo "  OUTPUT_IMAGE            - Output Docker image name (default: triton-minimal:TRITON_TAG)"
	@echo "  WRAPPER_DIR             - FastAPI wrapper template directory (default: template-serving)"
	@echo "  WRAPPER_IMAGE           - FastAPI wrapper image name"
	@echo "  SKIP_PULL               - Skip pulling latest images (default: false)"
	@echo "  VERBOSE                 - Enable verbose output (default: false)"
	@echo "  BUILD_DIR               - Build directory (default: build)"
	@echo ""
	@echo "Model Repository Storage:"
	@echo "  - Local filesystem: tritonserver --model-repository=/path/to/models"
	@echo "  - S3 bucket: tritonserver --model-repository=s3://bucket/path"
	@echo "    (requires AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY env vars)"
	@echo ""
	@echo "Examples:"
	@echo "  # Build minimal GPU image with default backends"
	@echo "  make build"
	@echo ""
	@echo "  # Build CPU-only with Python and ONNX backends"
	@echo "  make build ENABLE_GPU=OFF BACKENDS='python onnxruntime'"
	@echo ""
	@echo "  # Use Triton 24.10"
	@echo "  make build TRITON_TAG=24.10"
	@echo ""
	@echo "  # Build minimal container with Python only"
	@echo "  make build BACKENDS='python'"
	@echo ""
	@echo "  # Build FastAPI wrapper image"
	@echo "  make build-fastapi-wrapper"
	@echo ""

info:
	@echo "Build Configuration"
	@echo "==================="
	@echo "Triton Tag:        $(TRITON_TAG)"
	@echo "Backends:          $(BACKENDS) (+ ensemble core)"
	@echo "Repo Agents:       $(if $(REPOAGENTS),$(REPOAGENTS),none)"
	@echo "Build Type:        $(GPU_FLAG)"
	@echo "Full Image:        $(TRITON_FULL_IMAGE)"
	@echo "Min Image:         $(TRITON_MIN_IMAGE)"
	@echo "Output Image:      $(OUTPUT_IMAGE)"
	@echo "Dockerfile Dir:    $(DOCKERFILE_DIR)"
	@echo ""
	@echo "Model Repository (S3 Support):"
	@echo "  tritonserver --model-repository=s3://bucket/path"
	@echo "  Environment: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
	@echo ""
	@echo "Wrapper Template:"
	@echo "  Dir:   $(WRAPPER_DIR)"
	@echo "  Image: $(WRAPPER_IMAGE)"
	@echo ""
	@echo "Compose Flags:"
	@echo "$(COMPOSE_FLAGS)"
	@echo ""

# Generate Dockerfile using compose.py
compose: info
	@echo "Generating Dockerfile using compose.py..."
	@mkdir -p $(DOCKERFILE_DIR)
	cd $(TRITON_SRC) && python3 compose.py \
		--image full,$(TRITON_FULL_IMAGE) \
		--image min,$(TRITON_MIN_IMAGE) \
		--dry-run \
		$(COMPOSE_FLAGS)
	@echo ""
	@echo "Dockerfile generated at: $(DOCKERFILE_PATH)"
	@head -30 $(DOCKERFILE_PATH)
	@echo "... (see $(DOCKERFILE_PATH) for full content)"

# Build minimal Docker image using the composed Dockerfile
build: compose
	@echo ""
	@echo "Building Docker image: $(OUTPUT_IMAGE)..."
	docker build -t $(OUTPUT_IMAGE) -f $(DOCKERFILE_PATH) $(TRITON_BUILD_CONTEXT)
	@echo ""
	@echo "Build completed!"
	@echo "Image: $(OUTPUT_IMAGE)"
	@docker images $(OUTPUT_IMAGE)
	@echo ""
	@echo "To run the image:"
	@echo "  docker run --rm -p 8000:8000 -p 8001:8001 -p 8002:8002 $(OUTPUT_IMAGE)"
	@echo ""

# Build FastAPI wrapper template image (uses minimal Triton image as base)
build-fastapi-wrapper:
	@echo "Building FastAPI wrapper image: $(WRAPPER_IMAGE)..."
	docker build -t $(WRAPPER_IMAGE) -f $(WRAPPER_DIR)/Dockerfile $(WRAPPER_DIR)
	@echo ""
	@echo "Wrapper build completed!"
	@echo "Image: $(WRAPPER_IMAGE)"
	@docker images $(WRAPPER_IMAGE)

# Run FastAPI wrapper template image
run-fastapi-wrapper:
	@echo "Running FastAPI wrapper image: $(WRAPPER_IMAGE)..."
	docker run --rm -it \
		-p 8080:8080 -p 9001:9001 -p 9002:9002 -p 9090:9090 \
		-v $(abspath $(WRAPPER_DIR))/rootfs/model_repository:/model_repository \
		$(WRAPPER_IMAGE)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete."
