#!/bin/bash

cd ../..

# Build all services using jib directly to the local Docker daemon
cd eureka && ./mvnw clean compile jib:dockerBuild && cd ..
cd gateway && ./mvnw clean compile jib:dockerBuild && cd ..
cd configserver && ./mvnw clean compile jib:dockerBuild && cd ..
cd order && ./mvnw clean compile jib:dockerBuild && cd ..
cd user && ./mvnw clean compile jib:dockerBuild && cd ..
cd product && ./mvnw clean compile jib:dockerBuild && cd ..
cd notification && ./mvnw clean compile jib:dockerBuild && cd ..
