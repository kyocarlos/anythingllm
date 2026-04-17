#!/bin/bash
# AnythingLLM Collector 啟動腳本
# 解決 SSL 憑證和 integrity check 問題

cd /home/da40_ai_gb10/anything-llm/collector

# 設定環境變數
export NODE_ENV=development
export NODE_TLS_REJECT_UNAUTHORIZED=0
export STORAGE_DIR=/home/da40_ai_gb10/anything-llm/server/storage

# 啟動 collector
node index.js
