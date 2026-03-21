FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir locust==2.32.3

COPY locustfile.py .

EXPOSE 8089

ENTRYPOINT ["locust", "--host", "http://backend-service:8000"]
