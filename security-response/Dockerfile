FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl && \
    curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

WORKDIR /app
COPY webhook-handler.py .

EXPOSE 9000
CMD ["python", "webhook-handler.py"]
