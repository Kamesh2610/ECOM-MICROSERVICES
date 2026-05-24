#!/usr/bin/env bash
set -e

echo "========================================================================"
echo "🚀 Starting eCommerce Microservices Natively on macOS Host"
echo "========================================================================"

# 1. Setup Java 21 environment
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export PATH="$JAVA_HOME/bin:$PATH"

echo "☕ Using Java version:"
java -version

# 2. Set environment variables for databases and brokers (pointing to localhost)
export DB_USER="embarkx"
export DB_PASSWORD="embarkx"
export MONGO_URI="mongodb://localhost:27017"
export RABBITMQ_HOST="localhost"
export RABBITMQ_PORT="5672"
export RABBITMQ_USERNAME="guest"
export RABBITMQ_PASSWORD="guest"
export RABBITMQ_VHOST="/"

# 3. Create logs directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$PROJECT_ROOT/logs"

# 4. Build all microservices (each is an independent Maven project)
echo ""
build_needed=false
if [ "$1" = "--build" ]; then
    build_needed=true
else
    for svc in eureka configserver gateway product user order notification; do
        # Find any jar under target
        jar_file=$(find "$PROJECT_ROOT/$svc/target" -name "*.jar" 2>/dev/null | grep -v "sources" | head -n 1)
        if [ -z "$jar_file" ]; then
            build_needed=true
            break
        fi
    done
fi

if [ "$build_needed" = true ]; then
    echo "🛠️  Building all microservices (skipping tests)..."
    for svc in eureka configserver gateway product user order notification; do
        echo "   📦 Building $svc..."
        (cd "$PROJECT_ROOT/$svc" && "$JAVA_HOME/bin/java" -version > /dev/null 2>&1 && mvn clean package -DskipTests -q)
    done
    echo "✅ All Maven builds succeeded!"
else
    echo "⚡ JARs already exist. Skipping Maven build step (use --build to force rebuild)."
fi

# Helper function to launch a service
launch_service() {
    local name=$1
    local jar_path=$2
    shift 2
    local extra_args="$@"

    echo "⚙️  Starting $name..."
    nohup java -Dspring.cloud.inetutils.default-hostname=localhost \
               -Deureka.instance.prefer-ip-address=false \
               -Deureka.instance.hostname=localhost \
               $extra_args -jar "$PROJECT_ROOT/$jar_path" > "$PROJECT_ROOT/logs/$name.log" 2>&1 &
    echo "   PID=$!"
}

echo ""
echo "========================================================================"
echo "🏗️  Launching services in dependency order..."
echo "========================================================================"

# ── PHASE 1: Eureka Server (must be up first) ──────────────────────────
launch_service "eureka-server" "eureka/target/eureka-0.0.1-SNAPSHOT.jar"
echo "⏳ Waiting 12s for Eureka to initialize..."
sleep 12

# ── PHASE 2: Config Server (must be up before downstream services) ─────
CONFIG_LOCATION="file://$PROJECT_ROOT/configserver/src/main/resources/config"
launch_service "config-server" "configserver/target/configserver-0.0.1-SNAPSHOT.jar" \
    -Dspring.cloud.config.server.native.search-locations="$CONFIG_LOCATION" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/
echo "⏳ Waiting 12s for Config Server to initialize..."
sleep 12

# ── PHASE 3: Downstream microservices (all connect to Config Server + Eureka) ─

# Product Service (port 8081) — uses PostgreSQL
launch_service "product-service" "product/target/product-0.0.1-SNAPSHOT.jar" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    -Dspring.datasource.url=jdbc:postgresql://localhost:5432/productdb \
    -Dspring.datasource.username=embarkx \
    -Dspring.datasource.password=embarkx

# User Service (port 8082) — uses MongoDB + Keycloak
launch_service "user-service" "user/target/user-0.0.1-SNAPSHOT.jar" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    -Dspring.data.mongodb.uri=mongodb://localhost:27017 \
    -Dkeycloak.admin.server-url=http://localhost:8180

# Order Service (port 8083) — uses PostgreSQL + Kafka
launch_service "order-service" "order/target/order-0.0.1-SNAPSHOT.jar" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    -Dspring.datasource.url=jdbc:postgresql://localhost:5432/orderdb \
    -Dspring.datasource.username=embarkx \
    -Dspring.datasource.password=embarkx \
    -Dspring.cloud.stream.kafka.binder.brokers=localhost:9092

# Notification Service (port 8084) — uses Kafka
launch_service "notification-service" "notification/target/notification-0.0.1-SNAPSHOT.jar" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    -Dspring.cloud.stream.kafka.binder.brokers=localhost:9092

echo "⏳ Waiting 5s for downstream services to register..."
sleep 5

# ── PHASE 4: Gateway (starts last, discovers routes via Eureka) ─────────
launch_service "gateway-service" "gateway/target/gateway-0.0.1-SNAPSHOT.jar" \
    -Deureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/ \
    -Dspring.security.oauth2.resourceserver.jwt.issuer-uri=http://localhost:8180/realms/ecom-app

echo ""
echo "========================================================================"
echo "🎉 All microservices launched!"
echo ""
echo "📄 Logs directory: $PROJECT_ROOT/logs/"
echo "   eureka-server.log  | config-server.log  | gateway-service.log"
echo "   product-service.log | user-service.log   | order-service.log"
echo "   notification-service.log"
echo ""
echo "🌐 Key URLs:"
echo "   Eureka Dashboard : http://localhost:8761"
echo "   Config Server    : http://localhost:8888"
echo "   API Gateway      : http://localhost:8080"
echo "   Keycloak Admin   : http://localhost:8180  (admin / admin)"
echo "   RabbitMQ UI      : http://localhost:15672 (guest / guest)"
echo ""
echo "💡 To stop all services:  ./stop-apps-locally.sh"
echo "========================================================================"
