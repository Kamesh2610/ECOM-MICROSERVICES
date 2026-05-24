#!/usr/bin/env bash

echo "========================================================================"
echo "🛑 Stopping eCommerce Microservices..."
echo "========================================================================"

JARS=(
    "eureka-0.0.1-SNAPSHOT.jar"
    "configserver-0.0.1-SNAPSHOT.jar"
    "gateway-0.0.1-SNAPSHOT.jar"
    "user-0.0.1-SNAPSHOT.jar"
    "product-0.0.1-SNAPSHOT.jar"
    "order-0.0.1-SNAPSHOT.jar"
    "notification-0.0.1-SNAPSHOT.jar"
)

stopped_any=false

for jar in "${JARS[@]}"; do
    # Find process ID of the running jar
    pid=$(ps aux | grep "$jar" | grep -v grep | awk '{print $2}')
    if [ ! -z "$pid" ]; then
        echo "🛑 Stopping process $pid ($jar)..."
        kill "$pid"
        stopped_any=true
    fi
done

if [ "$stopped_any" = true ]; then
    echo "✅ All native microservices successfully stopped."
else
    echo "ℹ️ No running native microservices found."
fi
echo "========================================================================"
