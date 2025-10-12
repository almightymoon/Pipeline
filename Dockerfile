FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create a simple health check
RUN echo '#!/bin/bash\necho "OK"\nexit 0' > /app/health.sh && chmod +x /app/health.sh

# Expose port
EXPOSE 8080

# Default command
CMD ["python", "-c", "print('ML Pipeline Application Ready!'); import time; time.sleep(3600)"]
