#!/bin/bash
# =====================================================================
# Lab 23 - Background setup
# Cai dat: Go 1.22, act (GitHub Actions local runner), Docker Registry
# Khoi tao repo mau /root/cicd-app (nhanh main + nhanh feature/discount co bug)
# =====================================================================

STATUS_FILE="/tmp/lab-status.log"
GO_VERSION="1.22.12"
ACT_VERSION="v0.2.88"
RUNNER_IMAGE="catthehacker/ubuntu:act-22.04"
APP_DIR="/root/cicd-app"

status() { echo "$1" > "$STATUS_FILE"; }

# ---------------------------------------------------------------------
# 1. Cai dat Go toolchain tren host (de hoc vien chay test thu cong)
# ---------------------------------------------------------------------
status "Dang cai dat Go ${GO_VERSION}..."
if ! command -v go > /dev/null 2>&1; then
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
fi

# ---------------------------------------------------------------------
# 2. Cai dat act - chay workflow GitHub Actions ngay tren may
# ---------------------------------------------------------------------
status "Dang cai dat act ${ACT_VERSION}..."
if ! command -v act > /dev/null 2>&1; then
  curl -fsSL "https://github.com/nektos/act/releases/download/${ACT_VERSION}/act_Linux_x86_64.tar.gz" \
    | tar -xz -C /usr/local/bin act
  chmod +x /usr/local/bin/act
fi

# Cau hinh mac dinh cho act (tranh hoi chon image o lan chay dau tien)
cat << EOF > /root/.actrc
-P ubuntu-latest=${RUNNER_IMAGE}
--pull=false
--artifact-server-path /tmp/artifacts
EOF
mkdir -p /tmp/artifacts /root/ci-logs

# ---------------------------------------------------------------------
# 3. Docker Registry noi bo tai localhost:5000
# ---------------------------------------------------------------------
status "Dang khoi chay Docker Registry noi bo (localhost:5000)..."
docker rm -f registry > /dev/null 2>&1 || true
docker run -d --name registry --restart always -p 5000:5000 registry:2 > /dev/null 2>&1

# ---------------------------------------------------------------------
# 4. Khoi tao repo ung dung mau
# ---------------------------------------------------------------------
status "Dang khoi tao repository /root/cicd-app..."
git config --global user.name "DevOps Learner"
git config --global user.email "learner@devops.lab"
git config --global init.defaultBranch main

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || exit 1

cat << 'EOF' > go.mod
module cicd-app

go 1.22
EOF

cat << 'EOF' > main.go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
)

// Version la phien ban ung dung, duoc tra ve qua endpoint /healthz.
const Version = "1.0.0"

// HealthResponse mo ta du lieu tra ve cua endpoint /healthz.
type HealthResponse struct {
    Status  string `json:"status"`
    Version string `json:"version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(HealthResponse{Status: "ok", Version: Version})
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "CI/CD Demo Service v%s\n", Version)
}

func getPort() string {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    return port
}

func newMux() *http.ServeMux {
    mux := http.NewServeMux()
    mux.HandleFunc("/", rootHandler)
    mux.HandleFunc("/healthz", healthHandler)
    return mux
}

func main() {
    port := getPort()
    log.Printf("[INFO] cicd-app v%s listening on :%s", Version, port)
    log.Fatal(http.ListenAndServe(":"+port, newMux()))
}
EOF

cat << 'EOF' > main_test.go
package main

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
)

func TestHealthz(t *testing.T) {
    rec := httptest.NewRecorder()
    newMux().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

    if rec.Code != http.StatusOK {
        t.Fatalf("expected status 200, got %d", rec.Code)
    }
    var body HealthResponse
    if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
        t.Fatalf("invalid JSON: %v", err)
    }
    if body.Status != "ok" || body.Version != Version {
        t.Fatalf("unexpected body: %+v", body)
    }
}

func TestRoot(t *testing.T) {
    rec := httptest.NewRecorder()
    newMux().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

    if !strings.Contains(rec.Body.String(), "CI/CD Demo Service") {
        t.Fatalf("unexpected body: %q", rec.Body.String())
    }
}

func TestGetPort(t *testing.T) {
    t.Setenv("PORT", "")
    if got := getPort(); got != "8080" {
        t.Fatalf("expected default port 8080, got %s", got)
    }
    t.Setenv("PORT", "9090")
    if got := getPort(); got != "9090" {
        t.Fatalf("expected port 9090, got %s", got)
    }
}
EOF

# Dockerfile multi-stage + non-root (ke thua tu Lab 11)
cat << 'EOF' > Dockerfile
# ---------- Stage 1: Builder ----------
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/server .

# ---------- Stage 2: Runtime ----------
FROM alpine:3.19
RUN addgroup -g 10001 -S app && adduser -u 10001 -S -G app app
WORKDIR /app
COPY --from=builder --chown=10001:10001 /out/server /app/server
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/app/server"]
EOF

cat << 'EOF' > .dockerignore
.git
.github
coverage.out
*.md
EOF

cat << 'EOF' > .gitignore
coverage.out
EOF

cat << 'EOF' > README.md
# cicd-app

Go microservice minh hoa pipeline CI/CD.

- `GET /`        : thong tin dich vu
- `GET /healthz` : trang thai suc khoe + phien ban (JSON)

Chay test: `go test -v ./...`
EOF

# Chuan hoa format bang gofmt (heredoc dung space, gofmt doi sang tab)
gofmt -w main.go main_test.go 2> /dev/null || true

git init -q -b main
git remote add origin https://github.com/devops-labs/cicd-app.git
git add .
git commit -q -m "feat: khoi tao dich vu cicd-app voi endpoint /healthz"

# ---------------------------------------------------------------------
# 5. Nhanh feature/discount chua loi co y (cho Buoc 2)
#    - pricing.go sai format (gofmt) va sai logic tinh gia
# ---------------------------------------------------------------------
git checkout -q -b feature/discount

cat << 'EOF' > pricing.go
package main

import "errors"

// ErrInvalidPercent duoc tra ve khi phan tram giam gia nam ngoai khoang 0-100.
var ErrInvalidPercent = errors.New("percent must be between 0 and 100")

// ApplyDiscount tra ve gia sau khi giam (don vi VND).
func ApplyDiscount(price int, percent int) (int, error) {
    if percent < 0 || percent > 100 {
        return 0, ErrInvalidPercent
    }
    return price * percent / 100, nil
}
EOF

cat << 'EOF' > pricing_test.go
package main

import "testing"

func TestApplyDiscount(t *testing.T) {
    cases := []struct {
        name    string
        price   int
        percent int
        want    int
    }{
        {"giam 20 phan tram", 100000, 20, 80000},
        {"khong giam", 50000, 0, 50000},
        {"giam toan bo", 30000, 100, 0},
    }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            got, err := ApplyDiscount(tc.price, tc.percent)
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got != tc.want {
                t.Fatalf("ApplyDiscount(%d, %d) = %d, want %d", tc.price, tc.percent, got, tc.want)
            }
        })
    }
}

func TestApplyDiscountInvalidPercent(t *testing.T) {
    if _, err := ApplyDiscount(100000, 150); err != ErrInvalidPercent {
        t.Fatalf("expected ErrInvalidPercent, got %v", err)
    }
}
EOF

# Chi format file test; pricing.go co tinh giu sai format
gofmt -w pricing_test.go 2> /dev/null || true
git add .
git commit -q -m "feat: them ham tinh gia giam ApplyDiscount"
git checkout -q main

# ---------------------------------------------------------------------
# 6. Tai truoc cac image can thiet
# ---------------------------------------------------------------------
status "Dang tai image runner ${RUNNER_IMAGE} (~540MB, mat 1-3 phut)..."
docker pull golang:1.22-alpine > /dev/null 2>&1 &
docker pull alpine:3.19 > /dev/null 2>&1 &
docker pull "$RUNNER_IMAGE" > /dev/null 2>&1
wait

status "Hoan tat!"
touch /tmp/.lab_ready
