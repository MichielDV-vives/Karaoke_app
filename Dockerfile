# Base image supports Nvidia CUDA but does not require it and can also run demucs on the CPU
FROM nvidia/cuda:12.6.2-base-ubuntu22.04

USER root
ENV TORCH_HOME=/data/models
ENV OMP_NUM_THREADS=1

# Install required tools
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    git \
    python3 \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install FastAPI, Uvicorn, and python-multipart
RUN pip install fastapi uvicorn python-multipart

# Clone Demucs (now maintained in the original author's github space)
RUN git clone --single-branch --branch main https://github.com/adefossez/demucs /lib/demucs
WORKDIR /lib/demucs
# Checkout known stable commit on main
RUN git checkout b9ab48cad45976ba42b2ff17b229c071f0df9390

# Install dependencies with overrides for known working versions on this base image
RUN python3 -m pip install -e . "torch<2" "torchaudio<2" "numpy<2" --no-cache-dir
# Run once to ensure demucs works and trigger the default model download
RUN python3 -m demucs -d cpu test.mp3
# Cleanup output - we just used this to download the model
RUN rm -r separated

# Copy FastAPI application code
COPY main.py /lib/demucs/main.py
COPY index.html /lib/demucs/index.html

VOLUME /data/input
VOLUME /data/output
VOLUME /data/models

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]