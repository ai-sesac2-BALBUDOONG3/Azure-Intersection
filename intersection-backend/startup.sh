#!/bin/bash
set -e

# Oryx가 이미 APP_PATH, PYTHONPATH, 가상환경(antenv)을 설정해둔 상태에서
# 이 스크립트가 호출된다. 우리는 그냥 거기서 uvicorn만 실행하면 된다.

echo "[startup] PWD: $(pwd)"
echo "[startup] PYTHONPATH: $PYTHONPATH"

python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
