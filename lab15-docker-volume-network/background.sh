#!/bin/bash

# Tao thu muc lam viec cho lab
mkdir -p /root/docker-lab15

# Danh dau moi truong da san sang
touch /tmp/.lab_ready

# Tai truoc cac image can thiet trong background
docker pull alpine:3.19 > /dev/null 2>&1 &
docker pull redis:7-alpine > /dev/null 2>&1 &
