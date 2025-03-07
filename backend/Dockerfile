FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 環境変数PORTを設定し、その値をuvicornに渡す
ENV PORT=80
EXPOSE 80

CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
