# ===========================================================
# ML/AI Application Dockerfile with GPU Support
# Optimized for Deep Learning with CUDA, PyTorch, TensorFlow
# ===========================================================
FROM nvidia/cuda:11.8-devel-ubuntu22.04 as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=${CUDA_HOME}/bin:${PATH} \
    LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
    build-essential \
    curl \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python
RUN ln -s /usr/bin/python3.9 /usr/bin/python

# Upgrade pip and install basic packages
RUN python -m pip install --upgrade pip setuptools wheel

# ===========================================================
# Development Stage with Full ML Stack
# ===========================================================
FROM base as development

# Install PyTorch with CUDA support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install TensorFlow with GPU support
RUN pip install tensorflow[and-cuda]

# Install DeepSpeed and related packages
RUN pip install deepspeed transformers datasets accelerate

# Install ML development tools
RUN pip install \
    jupyter \
    jupyterlab \
    ipywidgets \
    matplotlib \
    seaborn \
    plotly \
    tensorboard \
    wandb \
    mlflow

# Install testing and quality tools
RUN pip install \
    pytest \
    pytest-cov \
    pytest-xdist \
    black \
    flake8 \
    mypy \
    isort

# Create app directory
WORKDIR /app

# Copy requirements for development
COPY requirements-ml-dev.txt /tmp/requirements-ml-dev.txt
RUN pip install -r /tmp/requirements-ml-dev.txt

# Copy source code
COPY . .

# Create necessary directories
RUN mkdir -p /app/data /app/models /app/logs /app/checkpoints /app/datasets

# Create non-root user
RUN groupadd -r mluser && useradd -r -g mluser mluser
RUN chown -R mluser:mluser /app
USER mluser

# Default command for development
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]

# ===========================================================
# Training Stage with DeepSpeed Support
# ===========================================================
FROM base as training

# Install PyTorch with CUDA support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install DeepSpeed and training dependencies
RUN pip install \
    deepspeed \
    transformers \
    datasets \
    accelerate \
    wandb \
    mlflow \
    tensorboard

# Install training requirements
COPY requirements-training.txt /tmp/requirements-training.txt
RUN pip install -r /tmp/requirements-training.txt

# Copy training code
WORKDIR /app
COPY src/ ./src/
COPY configs/ ./configs/
COPY scripts/ ./scripts/

# Create necessary directories
RUN mkdir -p /app/data /app/models /app/logs /app/checkpoints /app/datasets

# Create non-root user
RUN groupadd -r mluser && useradd -r -g mluser mluser
RUN chown -R mluser:mluser /app
USER mluser

# Default command for training
CMD ["python", "-m", "src.training.train"]

# ===========================================================
# Inference Stage (Optimized for Production)
# ===========================================================
FROM base as inference

# Install PyTorch with CUDA support (CPU-only for inference optimization)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install inference-specific packages
RUN pip install \
    transformers \
    onnxruntime-gpu \
    fastapi \
    uvicorn \
    pydantic \
    numpy \
    scipy

# Install inference requirements
COPY requirements-inference.txt /tmp/requirements-inference.txt
RUN pip install -r /tmp/requirements-inference.txt

# Copy inference code
WORKDIR /app
COPY src/inference/ ./src/inference/
COPY configs/ ./configs/
COPY models/ ./models/

# Create necessary directories
RUN mkdir -p /app/models /app/logs /app/cache

# Create non-root user
RUN groupadd -r mluser && useradd -r -g mluser mluser
RUN chown -R mluser:mluser /app
USER mluser

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Default command for inference
CMD ["python", "-m", "src.inference.main"]

# ===========================================================
# Triton Inference Server Stage
# ===========================================================
FROM nvcr.io/nvidia/tritonserver:23.10-py3 as triton

# Install additional Python packages for model conversion
RUN pip install \
    torch \
    transformers \
    onnx \
    onnxruntime-gpu

# Copy model conversion scripts
WORKDIR /app
COPY scripts/model_conversion/ ./scripts/model_conversion/
COPY configs/triton/ ./configs/triton/

# Create model repository structure
RUN mkdir -p /models

# Default command for Triton
CMD ["tritonserver", "--model-repository=/models"]
