#!/bin/bash

echo -n "Dang chuan bi moi truong thuc hanh Lab 9 (Docker CLI Fundamentals)... "

spin='-\|/'
i=0
while [ ! -f /tmp/.lab_ready ]; do
  i=$(( (i+1) % 4 ))
  printf "\b${spin:$i:1}"
  sleep 0.1
done

printf "\b \n"
echo -e "\033[0;32m[SUCCESS] Moi truong thuc hanh da san sang! Chuc ban hoc tap tot.\033[0m"
