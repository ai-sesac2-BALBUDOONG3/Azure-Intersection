#!/bin/bash
set -e

# Azure Linux App Service에서 코드가 올라오는 기본 경로
cd /home/site/wwwroot

echo "[startup] working dir: $(pwd)"

# 1) venv 없으면 생성 + 패키지 설치
if [ ! -d "antenv" ]; then
  echo "[startup] create virtualenv 'antenv'"
  python -m venv antenv
  source antenv/bin/activate

  echo "[startup] upgrade pip"
  pip install --upgrade pip

  echo "[startup] install requirements"
  pip install -r requirements.txt
else
  echo "[startup] reuse existing virtualenv 'antenv'"
  source antenv/bin/activate
fi

echo "[startup] launch uvicorn"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
