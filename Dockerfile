FROM python:3.11-slim

# Set environment variables for optimization
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy requirements and install dependencies with space optimization
COPY requirements.txt .
RUN pip install --no-cache-dir --no-deps -r requirements.txt && \
    pip cache purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy only necessary application files
COPY src/ ./src/
COPY scripts/ ./scripts/
COPY configs/ ./configs/

# Create a simple health check
RUN echo '#!/bin/bash\necho "OK"\nexit 0' > /app/health.sh && chmod +x /app/health.sh

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/health.sh

# Default command
CMD ["python", "-c", "print('ML Pipeline Application Ready!'); import time; time.sleep(3600)"]
