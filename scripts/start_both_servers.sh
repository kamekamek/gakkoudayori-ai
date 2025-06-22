#!/bin/bash

echo "🚀 Starting 学校だよりAI servers..."

# Kill any existing servers
echo "🔄 Stopping existing servers..."
pkill -f "flutter run" 2>/dev/null || true
pkill -f "start_server.py" 2>/dev/null || true
pkill -f ":8081" 2>/dev/null || true
sleep 2

# Start backend server
echo "📡 Starting backend server on port 8081..."
cd backend/functions
python3 start_server.py > ../../backend.log 2>&1 &
BACKEND_PID=$!
cd ../..

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 5

# Test backend connection
echo "🧪 Testing backend connection..."
for i in {1..10}; do
    if curl -s http://localhost:8081/api/v1/ai/health >/dev/null 2>&1; then
        echo "✅ Backend server is running!"
        break
    elif [ $i -eq 10 ]; then
        echo "❌ Backend server failed to start"
        exit 1
    else
        echo "⏳ Waiting for backend... ($i/10)"
        sleep 2
    fi
done

# Start frontend server
echo "🖥️ Starting Flutter frontend on port 8080..."
cd frontend
flutter run -d chrome --web-port=8080 \
    --dart-define=ENVIRONMENT=development \
    --dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai \
    > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

echo "✅ Both servers started!"
echo "📡 Backend: http://localhost:8081 (PID: $BACKEND_PID)"
echo "🖥️ Frontend: http://localhost:8080 (PID: $FRONTEND_PID)"
echo "🧪 API Test: http://localhost:8080/test_api_direct.html"
echo ""
echo "📋 Log files:"
echo "  Backend: backend.log"
echo "  Frontend: frontend.log"
echo ""
echo "🛑 To stop servers: pkill -f 'flutter run' && pkill -f 'start_server.py'"

# Keep script running and show logs
echo "📄 Showing backend logs (Ctrl+C to exit):"
tail -f backend.log