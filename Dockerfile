# Dockerfile for Azure Container App with AutoGen and Azure OpenAI
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir --index-url https://packagefeedproxy.microsoft.io/pypi/simple/ -r requirements.txt

COPY . .

CMD ["python", "main.py"]