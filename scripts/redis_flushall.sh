#!/bin/bash

docker compose exec redis-cluster-0 redis-cli flushall
docker compose exec redis-cluster-1 redis-cli flushall
docker compose exec redis-cluster-2 redis-cli flushall
docker compose exec redis-cluster-3 redis-cli flushall