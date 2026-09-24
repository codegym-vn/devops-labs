#!/bin/bash

# Tao thu muc ma nguon ung dung
mkdir -p /root/app

# Khoi tao ma nguon Go microservice
cat << 'EOF' > /root/app/main.go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/user"
	"time"
)

type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
}

type UserInfoResponse struct {
	UID       int    `json:"uid"`
	GID       int    `json:"gid"`
	Username  string `json:"username"`
	IsRoot    bool   `json:"is_root"`
	AppStatus string `json:"app_status"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	res := HealthResponse{
		Status:    "ok",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(res)
}

func userHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	uid := os.Getuid()
	gid := os.Getgid()
	username := "unknown"

	currentUser, err := user.Current()
	if err == nil {
		username = currentUser.Username
	}

	res := UserInfoResponse{
		UID:       uid,
		GID:       gid,
		Username:  username,
		IsRoot:    uid == 0,
		AppStatus: "Microservice running under Least Privilege policy",
	}
	json.NewEncoder(w).Encode(res)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "DevOps Production Go Microservice v1.0\n")
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/healthz", healthHandler)
	http.HandleFunc("/user", userHandler)

	log.Printf("[INFO] Server starting on port %s (UID: %d, GID: %d)...", port, os.Getuid(), os.Getgid())
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("[FATAL] Could not start server: %v", err)
	}
}
EOF

# Khoi tao file go.mod
cat << 'EOF' > /root/app/go.mod
module devops-app

go 1.22
EOF

# Tao file Dockerfile.naive (chua toi uu) de hoc vien doi chieu
cat << 'EOF' > /root/app/Dockerfile.naive
# [ANTI-PATTERN] Dockerfile don tang, khong toi uu cache va chay quyen root
FROM golang:1.22-alpine

WORKDIR /app

# Sao chep toan bo ma nguon truoc -> vo hieu hoa cache moi khi sua code
COPY . .

# Bien dich truc tiep tren image runtime nang > 300MB
RUN go build -o server main.go

# Chay mac dinh voi UID 0 (root)
EXPOSE 8080
CMD ["/app/server"]
EOF

# Danh dau he thong san sang ngay lap tuc
touch /tmp/.lab_ready

# Tai truoc base image trong background de tiet kiem thoi gian build
docker pull golang:1.22-alpine > /dev/null 2>&1 &
docker pull alpine:3.19 > /dev/null 2>&1 &
