#!/bin/bash
echo "Dang khoi dong PostgreSQL, Redis va chuan bi moi truong Flyway, vui long cho..."
while [ ! -f /tmp/.lab_ready ]; do sleep 1; done
echo "San sang! Ban co the bat dau thuc hanh."
