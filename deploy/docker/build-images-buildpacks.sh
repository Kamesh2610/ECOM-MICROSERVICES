#!/bin/bash

cd ../..

# Build all services with correct dcode007 tags to match docker-compose.yml
cd eureka && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/eureka-server && cd ..
cd gateway && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/gateway-service && cd ..
cd configserver && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/config-server && cd ..
cd order && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/order-service && cd ..
cd user && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/user-service && cd ..
cd product && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/product-service && cd ..
cd notification && ./mvnw spring-boot:build-image -DskipTests -Dspring-boot.build-image.imageName=dcode007/notification-service && cd ..
