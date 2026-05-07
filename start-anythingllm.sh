#!/bin/bash
# ==========================================
# AnythingLLM 完整服務啟動腳本
# 包含所有依賴服務
# 會自動檢查服務是否已啟動，已啟動則跳過
# ==========================================

echo "=========================================="
echo "  AnythingLLM 完整服務啟動"
echo "=========================================="

# 1. Neo4j
echo "[1/8] 啟動 Neo4j..."
if pgrep -f "neo4j" > /dev/null; then
    echo "  [SKIP] Neo4j 已啟動"
else
    sudo systemctl start neo4j
    echo "  [OK] Neo4j 啟動中"
fi

# 2. Ollama
echo "[2/8] 啟動 Ollama..."
if pgrep -f "ollama serve" > /dev/null; then
    echo "  [SKIP] Ollama 已啟動"
else
    ollama serve > /home/da40_ai_gb10/ollama.log 2>&1 &
    echo "  [OK] Ollama 啟動中"
fi

# 3. Qdrant (Docker)
echo "[3/8] 啟動 Qdrant..."
if docker ps | grep -q kb-qdrant; then
    echo "  [SKIP] Qdrant 已啟動"
else
    docker start kb-qdrant 2>/dev/null || \
    docker run -d --name kb-qdrant -p 6333:6333 -p 6334:6334 qdrant/qdrant
    echo "  [OK] Qdrant 啟動中"
fi

# 4. Hybrid Search API
echo "[4/8] 啟動 Hybrid Search API..."
if pgrep -f "hybrid_search_api" > /dev/null; then
    echo "  [SKIP] Hybrid Search API 已啟動"
else
    cd /home/da40_ai_gb10/graphrag
    nohup /home/da40_ai_gb10/mcp-env/bin/python3 hybrid_search_api.py > hybrid_search.log 2>&1 &
    echo "  [OK] Hybrid Search API 啟動中"
fi

# 5. AI Gateway
echo "[5/8] 啟動 AI Gateway..."
if pgrep -f "uvicorn.*8002" > /dev/null; then
    echo "  [SKIP] AI Gateway 已啟動"
else
    /home/da40_ai_gb10/ai-gateway/run-ai-gateway.sh start
    echo "  [OK] AI Gateway 啟動中"
fi

# 6. Nginx
echo "[6/8] 啟動 Nginx..."
if pgrep -f "nginx: master" > /dev/null; then
    echo "  [SKIP] Nginx 已啟動"
else
    sudo systemctl start nginx
    echo "  [OK] Nginx 啟動中"
fi

# 7. AnythingLLM Collector (文件收集器)
echo "[7/8] 啟動 AnythingLLM Collector..."
if pgrep -f "nodemon.*collector" > /dev/null; then
    echo "  [SKIP] Collector 已啟動"
else
    cd /home/da40_ai_gb10/anything-llm/collector
    nohup npm run dev > /tmp/anythingllm_collector.log 2>&1 &
    echo "  [OK] Collector 啟動中"
fi

# 8. AnythingLLM Server (主程式)
echo "[8/8] 啟動 AnythingLLM Server..."
if pgrep -f "node.*index.js" > /dev/null; then
    echo "  [SKIP] Server 已啟動"
else
    cd /home/da40_ai_gb10/anything-llm/server
    NODE_ENV=production nohup node index.js > /tmp/anythingllm.log 2>&1 &
    echo "  [OK] Server 啟動中"
fi

echo "=========================================="
echo "  等待服務啟動..."
sleep 5

echo "=========================================="
echo "  服務狀態檢查"
echo "=========================================="
echo "Ports listening:"
ss -tlnp 2>/dev/null | grep -E "3001|3000|8001|8002|11434|7687|7474|6333" | column -t

echo ""
echo "=========================================="
echo "  啟動完成！"
echo "=========================================="
echo ""
echo "服務 URLs:"
echo "  - AnythingLLM:       http://localhost:3001"
echo "  - Collector:         http://localhost:3000"
echo "  - Hybrid Search API: http://localhost:8001"
echo "  - AI Gateway:        http://localhost:8002"
echo "  - Ollama:            http://localhost:11434"
echo ""
echo "日誌檔案:"
echo "  - Ollama:           /home/da40_ai_gb10/ollama.log"
echo "  - Collector:        /tmp/anythingllm_collector.log"
echo "  - Server:           /tmp/anythingllm.log"
echo "  - Hybrid Search:    /home/da40_ai_gb10/graphrag/hybrid_search.log"