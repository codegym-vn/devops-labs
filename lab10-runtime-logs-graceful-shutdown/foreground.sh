#!/bin/bash

echo -n "Dang chuan bi moi truong thuc hanh Lab 10 (Docker Runtime, Logging & Signals)... "

spin='-\|/'
i=0
count=0
# Cho toi da 15 giay de tranh truong hop quay vo han
while [ ! -f /tmp/.lab_ready ] && [ $count -lt 150 ]; do
  i=$(( (i+1) % 4 ))
  printf "\b${spin:$i:1}"
  sleep 0.1
  count=$((count+1))
done

printf "\b \n"
echo -e "\033[0;32m[SUCCESS] Moi truong thuc hanh da san sang! Chuc ban hoc tap tot.\033[0m"
