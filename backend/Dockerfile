FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY fastapi_app /app/fastapi_app

ENV DB_HOST=db \
    DB_PORT=5432 \
    DB_NAME=pcsm \
    DB_USER=pcsm \
    DB_PASSWORD=pcsm \
    API_SECRET=change_me_secret

EXPOSE 8000
CMD ["uvicorn", "fastapi_app.main:app", "--host", "0.0.0.0", "--port", "8000"]
