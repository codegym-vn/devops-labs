# DevOps & Networking Labs

Kho lưu trữ mã nguồn các kịch bản thực hành tương tác (Interactive Scenarios) trên nền tảng **Killercoda**, được thiết kế chuyên sâu cho lộ trình đào tạo kỹ sư **DevOps, SRE và Cloud Systems**.

Tất cả các bài lab đều chạy trực tiếp trên môi trường ảo hóa Ubuntu, tích hợp cơ chế tự động hóa khởi tạo môi trường ngầm (Background Automation) và hệ thống script tự động chấm điểm (Automated Verification).

---

## 1. Danh Sách Các Bài Thực Hành

| Mã Lab | Thư Mục | Công Nghệ Chính | Trọng Tâm Kiến Thức | Thời Lượng |
|---|---|---|---|---|
| **Khởi Động** | `linux-terminal-navigation/` | Linux CLI, Bash, FHS, Navigation | Làm chủ Terminal, giải mã Prompt, điều hướng FHS (`cd`, `pwd`), quản lý tệp tin (`mkdir -p`, `touch`, `cp`, `mv`, `rm`) | 30-35 phút |
| **Thao Tác Tệp** | `linux-file-operations/` | Linux CLI, Files & Directories | Khởi tạo cấu trúc dự án đa tầng (`mkdir -p`, `touch`), sao chép/di chuyển/xóa (`cp`, `mv`, `rm`), đọc và theo dõi log (`cat`, `less`, `head`, `tail -f`) | 30-35 phút |
| **Pipe & Search** | `linux-pipe-redirect-search/` | Linux CLI, Streams, Pipes, find, grep | 3 luồng stdin/stdout/stderr, chuyển hướng (`>`, `2>`, `&>`), đường ống `\|`, tìm kiếm `find` và `grep -rn` | 30-35 phút |
| **Lab 1** | `lab1-tcpip-dns/` | Linux Networking, `iproute2`, `dig`, DNS | Mô hình TCP/IP 4 tầng, Subnetting & CIDR, Routing Table, phân tích luồng truy vấn DNS | 35-40 phút |
| **Lab 2** | `lab2-http-ssl-nginx/` | Nginx, OpenSSL, TLS 1.3, X.509 | Giao thức HTTP/HTTPS, bắt tay TLS 1.3 Handshake, SSL Termination, phân tích chứng chỉ số | 35-40 phút |
| **Lab 3** | `lab3-ssh-firewall/` | OpenSSH, UFW Firewall, Ed25519 | SSH Hardening (đổi cổng, tắt mật khẩu), mã hóa đường hầm SSH Tunneling, tường lửa UFW | 35-40 phút |
| **Lab 4** | `lab4-nginx-lb/` | Nginx Reverse Proxy, `wrk`, Python | Thuật toán cân bằng tải (Round Robin, Least Conn, IP Hash), Upstream Connection Pooling | 35-40 phút |
| **Lab 5** | `lab5-server-monitoring/` | Bash Shell, `/proc`, Webhook, Cron | Giám sát tài nguyên Linux (CPU, RAM, Disk), đánh giá ngưỡng, bắn cảnh báo Webhook JSON | 35-40 phút |
| **Lab 6** | `lab6-git-internals-hooks/` | Git CLI, Git Internals, Shell Hooks | 3 trạng thái Git, cấu trúc Git Objects (Blob, Tree, Commit), Git Hooks, khôi phục bằng Reflog | 35-40 phút |
| **Lab 7** | `lab7-git-conflicts-pr/` | Git Bare Repo, Trunk-Based, Rebase | Quản lý nhánh tập trung, giải quyết xung đột 3-Way Merge (`zdiff3`), Rebase và Squash PR | 35-40 phút |
| **Lab 8** | `lab8-postgres-redis-flyway/` | PostgreSQL 15, Redis 7, Flyway 9 | Kết nối an toàn qua biến môi trường (.env), Connection Pooling, Flyway Migration, Cache-Aside | 35-40 phút |
| **Lab 9** | `lab9-docker-cli-fundamentals/` | Docker CLI, Image Layers, `overlay2`, CoW | Tải và phân tích Image Layers, SHA256 digest, `run -it`, `exec -it`, `cp`, `diff`, `commit` | 35-40 phút |
| **Lab 10** | `lab10-runtime-logs-graceful-shutdown/` | Docker Runtime, cgroups, OOM Killer, Signals | Vòng đời container, tham số runtime, giới hạn CPU/RAM, Log Rotation, kiểm thử Graceful Shutdown | 35-40 phút |
| **Lab 11** | `lab11-dockerfile-multistage-security/` | Dockerfile, Multi-stage, BuildKit, Non-Root | Tối ưu layer cache, chống cache busting, Multi-stage build giảm 95% dung lượng, phân quyền non-root (UID 10001) | 35-40 phút |
| **Lab 12** | `lab12-cloud-vpc-vm-sg/` | AWS CLI, LocalStack, Docker, VPC, EC2, Security Groups | Xây dựng hạ tầng mạng VPC, phân vùng Subnet, cấu hình Security Groups, triển khai EC2 và kết nối SSH | 40-45 phút |
| **Lab 13** | `lab13-cloud-alb-asg/` | AWS CLI, LocalStack, Nginx, ALB, Auto Scaling, CloudWatch | Launch Template, Auto Scaling Group (min/max/desired), ALB + Target Group + Health Check, scale-out | 50-55 phút |
| **Lab 14** | `lab14-cloud-finops/` | AWS CLI, LocalStack, Python, Cost Allocation Tags, Budgets | Gắn Tags phân bổ chi phí, thiết lập Budget Alerts, phân tích Cost & Usage Report, phát hiện idle resources | 35-40 phút |
| **Lab 15** | `lab15-docker-volume-network/` | Docker CLI, Named Volume, Bridge Network, Embedded DNS, Redis | Khởi tạo Named Volume lưu trữ dữ liệu bền vững, cấu hình Custom Bridge Network, kết nối đa tầng và cô lập mạng | 35-40 phút |
| **Lab 16** | `lab16-cloud-terraform-cli/` | Terraform CLI, AWS Provider, LocalStack, IaC, HCL | Khởi tạo hạ tầng Cloud chuẩn IaC (VPC, Subnet, Security Group, EC2), làm chủ vòng đời init/plan/apply/destroy, quản trị state file | 40-45 phút |
| **Lab 17** | `lab17-cloud-terraform-modules-workspaces/` | Terraform Modules, Workspaces, LocalStack, Multi-Env | Đóng gói Child Modules tái sử dụng (VPC, Compute), cô lập trạng thái đa môi trường bằng Workspaces và file biến môi trường .tfvars | 45-50 phút |
| **Lab 18** | `lab18-cloud-terraform-remote-state-import/` | S3 Remote Backend, DynamoDB Lock, State Recovery, Import | Chuyển đổi Remote State S3 + DynamoDB Locking, xử lý kẹt khóa, can thiệp state mv/rm và import hạ tầng với khối import {} | 45-50 phút |
| **Lab 19** | `lab19-k8s-cluster-nodes/` | Kubernetes, Kubeadm 2 Nodes, kubectl, Node Management | Khám phá kubeconfig, đánh giá điều kiện sức khỏe Node (Conditions & Allocatable), gắn nhãn điều phối Pod và bảo trì Cordon/Uncordon | 35-40 phút |
| **Lab 20** | `lab20-k8s-pod-deployment-probes/` | Pod, Deployment, ReplicaSet, ConfigMap, Secret, Probes | Đóng gói Pod với giới hạn tài nguyên (Requests/Limits), tự phục hồi & scale với Deployment, nạp ConfigMap/Secret và kiểm tra sức khỏe Liveness/Readiness | 40-45 phút |
| **Lab 21** | `lab21-k8s-service-ingress-namespace-rbac/` | Namespace, ClusterIP, NodePort, Ingress, RBAC, ServiceAccount | Phân vùng tài nguyên Namespace, cân bằng tải ClusterIP & NodePort, định tuyến L7 với Ingress và kiểm soát truy cập phân quyền RBAC | 45-50 phút |
| **Lab 22** | `lab22-k8s-storage-statefulset-hpa-helm/` | StorageClass, PVC, StatefulSet, Headless Service, HPA, Helm | Cấp phát động StorageClass & PVC, triển khai cơ sở dữ liệu StatefulSet, tự động mở rộng theo tải với HPA và đóng gói ứng dụng bằng Helm Chart | 45-50 phút |
| **Lab 23** | `lab23-cicd-pipeline-test-package/` | GitHub Actions, act, Go test, Docker Registry | Pipeline as Code, quality gate (gofmt, vet, test, coverage 70%), Fail-Fast, đóng gói image gắn tag Git SHA, publish registry, smoke test & rollback | 45-50 phút |
| **Lab 24** | `lab24-k8s-canary-deployment/` | Kubernetes, Service, Canary, Zero-downtime, Rollback | Chiến lược Canary Deployment, điều phối traffic bằng Service selector, giám sát lỗi và rollback tức thì | 40-45 phút |
| **Lab 25** | `lab25-iac-security-checkov-tfsec/` | Terraform, Checkov, Tfsec, CIS Benchmarks, IaC SAST | Kiểm thử an ninh tĩnh cho Terraform, quét lỗi cấu hình và rò rỉ quyền, vá lỗ hổng và quản lý ngoại lệ | 40-45 phút |
| **Lab 26** | `lab26-secret-scanning-gitleaks/` | Gitleaks, Git Hooks, Pre-commit, Secret Detection | Tự động phát hiện rò rỉ secret trong mã nguồn và Git history, thiết lập Pre-commit Hook và cấu hình .gitleaksignore | 35-40 phút |
| **Lab 27** | `lab27-vault-secret-management/` | HashiCorp Vault, AppRole, KV-v2, Secret Injection | Quản trị bí mật với KV-v2, phân quyền Least Privilege với Vault Policy, xác thực AppRole và inject secret vào runtime | 40-45 phút |
| **Lab 28** | `lab28-security-gates-pipeline/` | DevSecOps, GitHub Actions, Security Gates, Trivy, Gitleaks | Xây dựng cổng kiểm soát an ninh đa tầng trong CI/CD (Secret Scan, SCA, Container Scan), tự động chặn release khi có lỗi Critical | 45-50 phút |
| **Lab 29** | `lab29-sonarqube-source-scan/` | SonarQube, SonarScanner, Quality Gates, SAST | Khởi chạy SonarQube Server, cấu hình SonarScanner, quét mã nguồn phân tích Bug/Vulnerability/Smell và cấu hình Quality Gate | 40-45 phút |
| **Lab 30** | `lab30-sast-vulnerability-fix/` | SAST, OWASP Top 10, SQLi, XSS, Path Traversal | Phân tích và khắc phục trực tiếp các lỗ hổng OWASP Top 10: SQL Injection (Parameterized Query), XSS, Path Traversal | 40-45 phút |
| **Lab 31** | `lab31-dast-owasp-zap/` | OWASP ZAP, DAST, Dynamic Scan, Helmet.js, Headers | Quét an ninh động DAST với ZAP Baseline Scan, phát hiện Missing Headers, Clickjacking, CSP và phòng thủ bằng Helmet | 40-45 phút |
| **Lab 32** | `lab32-dependency-vulnerability-scan/` | SCA, Trivy, npm audit, SBOM, CycloneDX, CVE | Quét phân tích thành phần phần mềm (SCA), bóc tách cây phụ thuộc, vá CVE Prototype Pollution/Command Injection, xuất SBOM | 40-45 phút |
| **Lab 33** | `lab33-docker-image-trivy-scan/` | Trivy, Docker Security, Multi-stage, Non-root, SBOM | Quét lỗ hổng từng layer của Docker Image, phát hiện misconfiguration trong Dockerfile, tối ưu Multi-stage Non-root và xuất SBOM | 40-45 phút |
| **Lab 34** | `lab34-docker-image-signing-cosign/` | Sigstore Cosign, OCI Registry, Image Signing, Verification | Ký số mật mã container image với Cosign, xác thực chữ ký số bằng Public Key, chống tấn công giả mạo Tampering, đính kèm SBOM | 40-45 phút |
| **Lab 35** | `lab35-app-metrics-instrumentation/` | Prometheus, prom-client, Node.js, Metrics (RED) | Gắn cảm biến đo lường vào ứng dụng (Counter, Gauge, Histogram đo p95), expose `/metrics`, thu thập realtime và truy vấn PromQL | 40-45 phút |
| **Lab 36** | `lab36-infra-metrics-logs/` | Node Exporter, Prometheus, Grafana Loki, Promtail | Giám sát hạ tầng toàn diện: thu thập OS/Hardware metrics qua Node Exporter, thu thập system logs qua Promtail & Loki, truy vấn LogQL | 40-45 phút |
| **Lab 37** | `lab37-centralized-logging/` | Fluent Bit, Grafana Loki, Nginx, LogQL, Routing | Xây dựng Pipeline Centralized Logging: Fluent Bit thu thập/parse JSON & Combined log, gắn nhãn filter, định tuyến đa luồng về Loki | 40-45 phút |
| **Lab 38** | `lab38-instrument-trace-request/` | OpenTelemetry, Jaeger, W3C Trace Context, Spans | Triển khai Distributed Tracing chuẩn OpenTelemetry: Jaeger All-in-One, Context Propagation (traceparent), phân tích Waterfall | 40-45 phút |
| **Lab 39** | `lab39-root-cause-analysis/` | RCA, SRE On-Call, Jaeger, Loki, 5 Whys, Hotfix | [Case Study] Đóng vai SRE On-Call điều tra P1 Incident: phối hợp Traces cô lập nút thắt, Logs tìm Root Cause (DB Pool), Hotfix và viết 5-Whys | 45-50 phút |
| **Lab 40** | `lab40-prometheus-exporters/` | Prometheus, Node Exporter, Redis Exporter, Hot-reload | Cấu hình Scrape Targets đa nguồn trong prometheus.yml, làm giàu nhãn metadata, phân tích OpenMetrics format và Hot-reload Zero-downtime | 40-45 phút |
| **Lab 41** | `lab41-promql-system-analysis/` | PromQL, Prometheus, RED Method, Histogram, Topk | Làm chủ truy vấn chuỗi thời gian, tính toán % CPU/RAM thực tế, phân tích SLA/SLO (Rate, Errors, p95 Duration) và điều kiện cảnh báo | 40-45 phút |
| **Lab 42** | `lab42-monitoring-dashboard/` | Grafana, Provisioning, Dashboard as Code, RED, Variables | Trực quan hóa số liệu tập trung: tự động hóa cấu hình bằng Provisioning YAML, thiết kế Panels (Stat, Gauge, Time-Series), mô hình RED và Dynamic Templating | 40-45 phút |
| **Lab 43** | `lab43-prometheus-alertmanager/` | Alertmanager, Alerting Rules, PromQL, Routing, Inhibition | Thiết lập hệ thống cảnh báo tự động: cấu hình Alerting Rules bằng PromQL, cây định tuyến Routing/Grouping, Inhibition chống bão alert và Silences | 40-45 phút |

---





## 2. Tóm Tắt Nội Dung Từng Bài Lab

### Khởi Động: Làm Quen Terminal & Điều Hướng Thư Mục Linux (`linux-terminal-navigation/`)
- Giải mã cấu trúc Terminal Prompt (`user@host:path$`), phân biệt tài khoản thường (`$`) và Root (`#`), nắm vững cú pháp lệnh Linux tiêu chuẩn.
- Thẩm tra danh tính phiên làm việc tức thì bằng `whoami`, `hostname`, `id`, `date`, `uname -a` và các biến môi trường `$USER`, `$HOME`, `$PWD`.
- Làm chủ bản đồ cây thư mục chuẩn FHS (`/`, `/etc`, `/var/log`, `/tmp`), phân biệt đường dẫn Tuyệt đối vs Tương đối và các ký hiệu đặc biệt (`.`, `..`, `~`, `-`).
- Khởi tạo kiến trúc thư mục đa cấp với `mkdir -p` (Brace Expansion), tạo tệp với `touch`, sao chép đệ quy `cp -r`, di chuyển/đổi tên `mv`, xóa dữ liệu với `rm` và trực quan hóa với `tree`.

### Nền Tảng: Thao Tác Tệp & Thư Mục Trong Linux (`linux-file-operations/`)
- Khởi tạo kiến trúc dự án đa tầng với `mkdir -p` (Brace Expansion), tạo tệp và ghi dữ liệu với `touch`, `echo >` và Here-Doc.
- Thực hiện sao lưu giữ thuộc tính (`cp -p`), sao chép đệ quy (`cp -r`), di chuyển và đổi tên tệp/thư mục (`mv`).
- Dọn dẹp tệp tin an toàn với `rm` và `rmdir`, phòng ngừa các sự cố rủi ro dữ liệu.
- Đọc, kiểm tra và phân tích tệp nhật ký ứng dụng với bộ công cụ `cat -n`, `less`, `head`, `tail`, `wc -l` và giám sát thời gian thực `tail -f`.

### Nền Tảng: Pipe, Redirect & Tìm Kiếm Trong Linux (`linux-pipe-redirect-search/`)
- Quản trị 3 luồng dữ liệu chuẩn `stdin` (0), `stdout` (1), `stderr` (2) và kỹ thuật chuyển hướng dữ liệu với `>`, `>>`, `2>`, `2>&1`, `/dev/null`.
- Xây dựng chuỗi xử lý dữ liệu tự động với đường ống Pipe (`|`) kết hợp các bộ lọc `grep`, `wc`, `sort`, `uniq` và ngã ba đường ống `tee`.
- Thực hành tìm kiếm tệp tin theo thuộc tính bằng `find` và truy vết nội dung/chuỗi bí mật đệ quy với `grep -rn`.

### Lab 1: TCP/IP và DNS Trong DevOps (`lab1-tcpip-dns/`)
- Tính toán phân chia mạng con (Subnetting, CIDR, Network ID, Broadcast IP) cho VPC và mạng container.
- Phân tích bảng định tuyến và giao diện mạng Linux bằng công cụ `iproute2` (`ip addr`, `ip route`).
- Kiểm tra cổng và trạng thái kết nối mạng với `ss` và `nc` (Netcat).
- Chẩn đoán chuỗi phân giải DNS từ local cache tới Authoritative Server bằng `dig +trace`.

### Lab 2: HTTP/HTTPS, TLS 1.3 và Nginx SSL (`lab2-http-ssl-nginx/`)
- Phân tích cấu trúc bản tin HTTP/1.1 và các trường Header bảo mật quan trọng.
- Khám phá tiến trình bắt tay TLS 1.3 Handshake (1-RTT) và trao đổi khóa bất đối xứng.
- Tự tạo chứng chỉ số self-signed X.509 bằng OpenSSL và cấu hình SSL Termination trên Nginx.
- Thiết lập điều hướng tự động từ HTTP (Port 80) sang HTTPS (Port 443) bằng mã trạng thái 301.

### Lab 3: SSH Hardening, Tunneling và UFW Firewall (`lab3-ssh-firewall/`)
- Gia cố bảo mật dịch vụ OpenSSH: Đổi cổng mặc định, vô hiệu hóa đăng nhập bằng mật khẩu, chỉ cho phép khóa Ed25519.
- Thiết lập đường hầm SSH Local Port Forwarding (`-L`) để truy cập dịch vụ nội bộ không mở ra Internet.
- Cấu hình tường lửa UFW theo nguyên tắc phòng thủ đa lớp (Defense in Depth) và hạn chế tần suất (`ufw limit`).

### Lab 4: Nginx Reverse Proxy, Load Balancing và Connection Pooling (`lab4-nginx-lb/`)
- Cấu hình Nginx đóng vai trò Reverse Proxy chuyển tiếp lưu lượng với đầy đủ các header định danh client.
- Triển khai và so sánh 3 thuật toán cân bằng tải: Round Robin, Least Connections và IP Hash.
- Thiết lập Upstream Connection Pooling (`keepalive`) để tái sử dụng socket TCP, giảm tải bắt tay và tăng RPS.
- Đo lường hiệu năng thực tế bằng công cụ `wrk` trước và sau khi kích hoạt Connection Pooling.

### Lab 5: Giám Sát Tài Nguyên Hệ Thống và Tự Động Hóa Cảnh Báo (`lab5-server-monitoring/`)
- Thu thập số liệu hiệu năng Linux trực tiếp từ kernel (`/proc/stat`, `/proc/meminfo`, `df`).
- Xây dựng script giám sát `monitor.sh` với cơ chế đánh giá ngưỡng linh hoạt (WARNING, CRITICAL).
- Tích hợp gửi cảnh báo tự động định dạng JSON qua HTTP Webhook (hỗ trợ Slack, Discord, Mock Receiver).
- Lập lịch tự động hóa 24/7 với Cron và quản lý xoay vòng file nhật ký (Log Rotation).

### Lab 6: Git Internals, Reflog và Git Hooks Automation (`lab6-git-internals-hooks/`)
- Bóc tách bản chất cấu trúc lưu trữ nội tại của Git: Blob, Tree, Commit và cơ chế mã băm SHA-1.
- Tự động hóa kiểm tra chất lượng mã nguồn bằng `pre-commit` hook (chặn lộ secret, format code).
- Chuẩn hóa thông điệp commit theo Conventional Commits bằng hook `commit-msg`.
- Cứu hộ dữ liệu và khôi phục các commit bị mất sau thao tác `git reset --hard` thông qua Git Reflog.

### Lab 7: Chiến Lược Nhánh, Giải Quyết Xung Đột và Pull Request (`lab7-git-conflicts-pr/`)
- Áp dụng mô hình phân nhánh Trunk-Based Development với Central Bare Repository thực tế.
- Khám phá và xử lý xung đột hợp nhất đa file bằng kỹ thuật 3-Way Merge và chế độ hiển thị `zdiff3`.
- Vận dụng quy trình Rebase từng bước (`git rebase --continue`) để giữ lịch sử commit thẳng hàng.
- Thực hiện đóng gói mã nguồn tính năng bằng kỹ thuật Squash & Merge chuẩn mực trước khi đưa vào sản xuất.

### Lab 8: Kết Nối PostgreSQL, Redis và Chạy Flyway Migration (`lab8-postgres-redis-flyway/`)
- Quản lý cấu hình kết nối an toàn qua biến môi trường (`.env`, `DATABASE_URL`, `REDIS_URL`) theo chuẩn 12-Factor App.
- Thiết lập và phân tích cơ chế Connection Pooling (`DB_POOL_MIN`, `DB_POOL_MAX`) giúp tối ưu tài nguyên mạng.
- Quản lý phiên bản CSDL tự động với Flyway (Migration scripts V1, V2) và kiểm tra tính toàn vẹn (Checksum, Foreign Key).
- Triển khai mô hình bộ nhớ đệm Cache-Aside với Redis và đo lường độ trễ truy vấn thực tế.

### Lab 9: Nhập Môn Docker CLI, Cấu Trúc Image Layers & Tương Tác Container (`lab9-docker-cli-fundamentals/`)
- Khám phá cơ chế phân tầng (Image Layers) bất biến và mã băm SHA256 digest của Docker Image.
- Sử dụng thành thạo `docker pull`, `docker history`, `docker inspect` và quản lý phiên bản với `docker tag`.
- Phân biệt và làm chủ `docker run -it` (môi trường mới) và `docker exec -it` (thâm nhập container đang chạy nền).
- Sao chép dữ liệu hai chiều giữa Host và Container với `docker cp`, truy vết thay đổi file với `docker diff`.
- Thấu hiểu cơ chế Copy-on-Write (CoW) của storage driver `overlay2` và đóng gói snapshot bằng `docker commit`.

### Lab 10: Cấu Hình Tài Nguyên Runtime, Quản Lý Log Container & Graceful Shutdown (`lab10-runtime-logs-graceful-shutdown/`)
- Quản trị vòng đời container (`create`, `start`, `stop`, `pause`, `rm`) và nạp biến môi trường an toàn từ `--env-file`.
- Thiết lập giới hạn phần cứng với cgroups Linux (`--cpus 0.5`, `--memory 256m`, `--memory-swap 256m`) và chính sách phục hồi `--restart unless-stopped`.
- Thực nghiệm kích hoạt Linux OOM Killer (mã thoát 137, `OOMKilled: true`) khi tiến trình bị rò rỉ bộ nhớ.
- Cấu hình tự động xoay vòng log (**Log Rotation**: `--log-opt max-size=2m --log-opt max-file=3`) chống nguy cơ đầy 100% dung lượng đĩa máy chủ.
- Xử lý bài toán PID 1 (Exec form vs Shell form), bắt tín hiệu `SIGTERM (15)` và kiểm thử quy trình **Graceful Shutdown** rút cạn kết nối an toàn (`ExitCode: 0`).

### Lab 11: Thiết Kế Dockerfile Multi-stage, Tối Ưu Cache & Phân Quyền Non-Root (`lab11-dockerfile-multistage-security/`)
- Phân tích cơ chế băm nội dung của Docker BuildKit, hiện tượng Cache Busting và thiết lập file `.dockerignore`.
- Tối ưu hóa thứ tự các chỉ thị: nạp file mô tả dependencies trước, source code sau để đạt 100% tỷ lệ Cache Hit.
- Áp dụng kỹ thuật Multi-stage build tách bạch môi trường Builder và Runtime, giảm dung lượng image từ hơn 300MB xuống chỉ còn xấp xỉ 15MB.
- Sử dụng các cờ biên dịch tối ưu kích thước file nhị phân tĩnh (`CGO_ENABLED=0`, `-ldflags="-s -w"`).
- Triển khai nguyên tắc đặc quyền tối thiểu (Least Privilege), tạo user/group non-root và chạy tiến trình dưới quyền `USER 10001:10001` đạt chuẩn an toàn Kubernetes và CIS Docker Benchmark.

### Lab 12: Xây Dựng Mạng VPC & Security Groups trên Cloud (`lab12-cloud-vpc-vm-sg/`)
- Khởi tạo kiến trúc mạng cô lập VPC `10.0.0.0/16`, phân vùng Public Subnet và Private Subnet bằng AWS CLI.
- Thiết lập Internet Gateway (IGW) và cấu hình bảng định tuyến Route Table cho phép truy cập Internet.
- Cấu hình tường lửa Security Groups đa tầng (web-sg mở port 80/443, db-sg chỉ mở port 5432 tham chiếu từ web-sg).
- Khởi tạo SSH Key Pair, chạy máy ảo EC2 và dọn dẹp tài nguyên (FinOps).

### Lab 13: Cân Bằng Tải ALB & Cụm Máy Chủ Auto Scaling Group (`lab13-cloud-alb-asg/`)
- Tạo Launch Template chuẩn hóa cấu hình máy chủ kèm User Data khởi chạy ứng dụng.
- Triển khai cụm máy chủ tự động mở rộng Auto Scaling Group (ASG) đa vùng sẵn sàng cao.
- Cấu hình Application Load Balancer (ALB) và Target Group kèm kiểm tra sức khỏe (Health Check).
- Giả lập mở rộng quy mô (Scale-Out) và thực hành quy trình dọn dẹp tài nguyên.

### Lab 14: FinOps — Quản Lý và Tối Ưu Chi Phí Cloud (`lab14-cloud-finops/`)
- Gắn Cost Allocation Tags lên tài nguyên Cloud theo chuẩn quản trị (Project, Environment, CostCenter).
- Thiết lập hạn mức chi phí AWS Budgets và cấu hình cảnh báo ngưỡng (Budget Alerts).
- Phân tích báo cáo chi phí Cost & Usage Report (CUR) đa chiều bằng script tự động.
- Phát hiện tài nguyên lãng phí (idle resources), lập báo cáo FinOps và thực thi hủy máy ảo bằng AWS CLI.

### Lab 15: Docker Named Volume, Custom Bridge Network & Kết Nối Container (`lab15-docker-volume-network/`)
- Khởi tạo và quản trị Named Volume, kiểm chứng cơ chế lưu trữ dữ liệu bền vững qua vòng đời container.
- Tạo Custom Bridge Network với dải Subnet quy hoạch chuẩn và khám phá cơ chế Embedded DNS (`127.0.0.11`).
- Triển khai mô hình ứng dụng đa tầng (Redis DB + Web Client) kết nối nội bộ an toàn bằng Container Name.
- Kiểm thử nguyên tắc cô lập mạng (Network Isolation) và thực hành kết nối mạng động (`docker network connect`).

### Lab 16: Thực Hành Khởi Tạo Hạ Tầng Cloud Cơ Bản Bằng Terraform CLI (`lab16-cloud-terraform-cli/`)
- Tiếp cận tư duy Declarative Infrastructure as Code (IaC) và cấu hình AWS Provider trỏ tới LocalStack.
- Lập trình mạng VPC, Public/Private Subnet, Internet Gateway và tham số hóa cấu hình với Variables & Outputs.
- Làm chủ chu trình kinh điển: `terraform init`, `validate`, `plan -out`, `apply` và mổ xẻ file trạng thái `terraform.tfstate`.
- Thực hiện cập nhật hạ tầng tại chỗ (In-Place Drift Update), kiểm chứng tính Idempotent và dọn dẹp an toàn bằng `terraform destroy`.

### Lab 17: Đóng Gói Terraform Module & Quản Lý Đa Môi Trường Workspaces (`lab17-cloud-terraform-modules-workspaces/`)
- Phân tách và đóng gói mã nguồn thành các Child Modules tái sử dụng (`modules/vpc`, `modules/compute`).
- Thiết lập hợp đồng giao tiếp chuẩn giữa các module qua `variables.tf` và `outputs.tf`.
- Quản lý và cô lập trạng thái hạ tầng đa môi trường (`dev`, `prod`) bằng Terraform Workspaces.
- Cấu hình linh hoạt quy mô máy ảo và IP range tương ứng theo từng môi trường với các file `.tfvars`.

### Lab 18: Remote Backend, Khôi Phục Sự Cố State & Import Hạ Tầng (`lab18-cloud-terraform-remote-state-import/`)
- Chuyển đổi trạng thái lưu trữ hạ tầng sang Remote Backend AWS S3 kết hợp DynamoDB State Locking.
- Xử lý sự cố kẹt khóa và can thiệp state nâng cao (`terraform force-unlock`, `terraform state mv`, `terraform state rm`).
- Đưa tài nguyên tạo thủ công ngoài luồng vào quản lý bằng lệnh `terraform import` truyền thống.
- Sử dụng khối khai báo hiện đại `import {}` (từ Terraform 1.5+) tự động sinh mã HCL và kiểm chứng tính đồng bộ 3 bên.

### Lab 19: Quản Trị Cụm Kubernetes & Kiểm Tra Trạng Thái Node Qua kubectl (`lab19-k8s-cluster-nodes/`)
- Khám phá kiến trúc cụm K8s giữa Control Plane và Worker Nodes cùng cấu trúc tệp xác thực `~/.kube/config`.
- Phân tích và đánh giá trạng thái vận hành của Node qua các điều kiện sức khỏe và tỷ lệ tài nguyên khả dụng.
- Quản trị siêu dữ liệu của Node bằng Labels và Annotations phục vụ việc phân loại và định tuyến Pod có điều kiện.
- Thực thi quy trình bảo trì máy chủ an toàn trong môi trường Production thông qua các lệnh điều phối nút mạng.

### Lab 20: Đóng Gói Pod, Triển Khai Deployment, Nạp ConfigMap/Secret & Cấu Hình Probes (`lab20-k8s-pod-deployment-probes/`)
- Khởi tạo Pod chuẩn khai báo YAML, áp dụng kỹ thuật `--dry-run=client` và cấu hình hạn mức tài nguyên tính toán (Requests & Limits) phòng tránh OOMKilled.
- Quản trị vòng đời ứng dụng với Deployment và ReplicaSet, thực nghiệm cơ chế tự phục hồi (Self-healing) và mở rộng quy mô linh hoạt (Scale Out/In).
- Phân tách cấu hình khỏi mã nguồn (Twelve-Factor App), bảo mật thông tin nhạy cảm với Secret và nạp biến môi trường động vào Pod.
- Thiết lập hệ thống giám sát sức khỏe container thông minh với Liveness Probe (tự restart) và Readiness Probe (kiểm soát điều phối traffic mạng).

### Lab 21: Cấu Hình Service, Ingress, Phân Vùng Namespace & Phân Quyền RBAC (`lab21-k8s-service-ingress-namespace-rbac/`)
- Phân vùng logic tài nguyên cụm K8s với Namespace, cô lập không gian giữa các đội ngũ và môi trường triển khai.
- Cấu hình cân bằng tải nội bộ với Service kiểu ClusterIP và phơi bày cổng máy chủ ra mạng ngoài với NodePort.
- Thiết lập quy tắc định tuyến HTTP/HTTPS tầng 7 thông minh dựa trên đường dẫn URL (Path-based Routing) thông qua Ingress.
- Xây dựng ma trận kiểm soát quyền truy cập tối thiểu (Principle of Least Privilege) với ServiceAccount, Role, RoleBinding và kiểm thử với lệnh `kubectl auth can-i`.

### Lab 22: Cấp Phát Động StorageClass, Triển Khai StatefulSet, Cấu Hình HPA & Đóng Gói Helm Chart (`lab22-k8s-storage-statefulset-hpa-helm/`)
- Cấu hình cấp phát động bộ lưu trữ bền vững thông qua StorageClass và PersistentVolumeClaim (PVC), bảo toàn dữ liệu khi xóa Pod.
- Triển khai cụm cơ sở dữ liệu có trạng thái với StatefulSet, Headless Service và cơ chế tự động sinh ổ đĩa độc lập qua `volumeClaimTemplates`.
- Thiết lập tự động co giãn quy mô số lượng bản sao theo tải CPU thời gian thực bằng Horizontal Pod Autoscaler (HPA) và Metrics-Server.
- Đóng gói chuẩn hóa ứng dụng microservice thành Helm Chart, tham số hóa cấu hình qua Values và quản trị vòng đời phát hành ứng dụng.

### Lab 23: Xây Dựng Pipeline CI/CD Cơ Bản — Kiểm Thử & Đóng Gói Ứng Dụng (`lab23-cicd-pipeline-test-package/`)
- Viết workflow GitHub Actions (Pipeline as Code) với trigger, job, step và chạy cục bộ bằng `act` trên runner container.
- Thiết lập chuỗi quality gate: kiểm tra format `gofmt`, phân tích tĩnh `go vet`, unit test và ngưỡng coverage 70%.
- Thực hành vòng Fail-Fast trên nhánh tính năng có lỗi: đọc log pipeline đỏ, sửa format và bug logic, rebase và merge an toàn vào `main`.
- Đóng gói Docker image bất biến với job phụ thuộc `needs`, điều kiện `if`, gắn tag Git SHA + `latest`, publish lên registry nội bộ và lưu artifact coverage.
- Tự động smoke test image sau build, phát hành phiên bản mới và diễn tập rollback bằng tag SHA.

### Lab 24: Triển Khai Ứng Dụng Lên Cụm Kubernetes Theo Chiến Lược Canary Deployment (`lab24-k8s-canary-deployment/`)
- Làm chủ chiến lược phát hành phần mềm không gián đoạn (Zero-downtime) chuẩn doanh nghiệp với Stable v1 và Canary v2.
- Điều phối lưu lượng giao thông thông minh qua Kubernetes Service selector và trọng số Pod phân bổ tải.
- Tự động hóa giám sát sức khỏe, tỷ lệ lỗi và tiến hành thăng cấp phiên bản (Promotion) an toàn lên toàn cụm.
- Mô phỏng sự cố phiên bản mới và kích hoạt cơ chế Rollback khẩn cấp tức thì bảo vệ trải nghiệm người dùng.

### Lab 25: Quét Lỗ Hổng Bảo Mật Mã Nguồn Terraform Với Checkov & Tfsec (`lab25-iac-security-checkov-tfsec/`)
- Tiếp cận tư duy kiểm thử an ninh tĩnh (SAST) chuyên sâu cho hạ tầng dạng mã nguồn (IaC).
- Khám phá mã nguồn Terraform, phát hiện cấu hình sai lệch và rò rỉ quyền truy cập bằng công cụ Tfsec.
- Quét phân tích chuyên sâu tuân thủ bộ tiêu chuẩn bảo mật quốc tế CIS Benchmarks với Checkov.
- Khắc phục toàn diện các vi phạm an ninh (Remediation) và quản lý ngoại lệ an toàn qua cơ chế Suppression.

### Lab 26: Tự Động Quét Lộ Mật Khẩu, Token & Khóa Bí Mật Với Gitleaks (`lab26-secret-scanning-gitleaks/`)
- Nhận thức rủi ro rò rỉ thông tin mật (Secret Leak) và thực thi quét tự động mã nguồn với Gitleaks CLI.
- Rà soát toàn bộ lịch sử Git Commit để truy vết các thông tin mật từng bị commit ngoài ý muốn và xuất báo cáo SARIF/JSON.
- Thiết lập Git Pre-commit Hook tự động ngăn chặn lập trình viên commit credentials ngay từ máy trạm.
- Quản trị quy tắc ngoại lệ linh hoạt bằng tệp cấu hình `.gitleaksignore` và bộ rule regex tùy chỉnh.

### Lab 27: Quản Trị & Inject Secret An Toàn Vào Pipeline Với HashiCorp Vault (`lab27-vault-secret-management/`)
- Khởi tạo cụm HashiCorp Vault Server, làm chủ cơ chế lưu trữ mật mã phiên bản Key-Value (KV-v2) Secrets Engine.
- Thiết lập ma trận phân quyền tối thiểu (Principle of Least Privilege) bằng Vault Policy dạng HCL.
- Cấu hình phương thức xác thực chuẩn CI/CD bằng Vault AppRole (Role ID & Secret ID).
- Inject động các tham số bí mật vào ứng dụng lúc khởi chạy (Runtime) mà không lưu vết trong mã nguồn hay image.

### Lab 28: Xây Dựng Security Gates Trong CI/CD Pipeline (`lab28-security-gates-pipeline/`)
- Hiện thực hóa mô hình DevSecOps chuẩn doanh nghiệp qua quy trình kiểm soát an ninh đa tầng (Shift-Left Security).
- Tích hợp liên hoàn 3 cổng kiểm soát (Security Gates): Secret Scanning (Gate 1), Phân tích thư viện phụ thuộc SCA (Gate 2) và Quét lỗ hổng Container Image (Gate 3).
- Thiết lập quy tắc tự động ngắt pipeline (Fail Pipeline) khi phát hiện lỗ hổng mức độ Critical/High.
- Diễn tập phát hành ứng dụng an toàn khi toàn bộ các tiêu chí an ninh được đáp ứng.

### Lab 29: Cấu Hình SonarQube Quét Mã Nguồn & Phân Tích Chất Lượng (`lab29-sonarqube-source-scan/`)
- Khởi chạy máy chủ SonarQube Server chuyên nghiệp và làm quen với giao diện phân tích mã nguồn.
- Cấu hình SonarScanner CLI, tạo dự án và quản lý token xác thực an toàn.
- Thiết lập tệp cấu hình `sonar-project.properties` tối ưu cho các ngôn ngữ lập trình phổ biến.
- Đọc hiểu báo cáo Bugs, Vulnerabilities, Security Hotspots, Code Smells và thiết lập Cổng chất lượng Quality Gate.

### Lab 30: Phân Tích Lỗ Hổng Mã Nguồn & Kỹ Thuật Sửa Lỗi An Toàn (`lab30-sast-vulnerability-fix/`)
- Quét mã nguồn bằng công cụ SAST và phân loại mức độ rủi ro theo tiêu chuẩn bảo mật OWASP Top 10.
- Giải mã cơ chế tấn công và vá triệt để lỗ hổng SQL Injection bằng kỹ thuật Parameterized Queries / Prepared Statements.
- Khắc phục lỗ hổng Cross-Site Scripting (XSS) thông qua Data Sanitization và Content Encoding.
- Xử lý lỗ hổng Path Traversal (Directory Traversal) bằng kỹ thuật kiểm tra ranh giới đường dẫn an toàn (Safe Path Handling).

### Lab 31: Tích Hợp OWASP ZAP Quét Ứng Dụng Đang Chạy (DAST) (`lab31-dast-owasp-zap/`)
- Tiếp cận phương pháp kiểm thử an ninh động (Dynamic Application Security Testing - DAST) trên ứng dụng runtime.
- Thực thi quét tự động với OWASP ZAP Baseline Scan để phát hiện các lỗ hổng thời gian thực.
- Phân tích các mối nguy hiểm: Thiếu Security Headers, Clickjacking, lỏng lẻo Content Security Policy (CSP) và lộ thông tin nhạy cảm.
- Triển khai middleware phòng thủ toàn diện với Helmet.js và quét nghiệm thu an toàn sau khi vá lỗi.

### Lab 32: Quét Lỗ Hổng Dependency Trong Ứng Dụng (SCA) (`lab32-dependency-vulnerability-scan/`)
- Khảo sát cấu trúc phụ thuộc trực tiếp và gián tiếp (Direct vs Transitive Dependencies) của dự án.
- Quét phân tích thành phần phần mềm (SCA) bằng Trivy và npm audit để phát hiện các mã định danh CVE.
- Phân tích cơ chế khai thác các lỗ hổng kinh điển: Prototype Pollution và Remote Command Injection.
- Nâng cấp phiên bản an toàn, thiết lập Dependency Security Gate trong CI/CD và xuất danh mục SBOM chuẩn CycloneDX.

### Lab 33: Quét Docker Image Với Trivy (Container Security) (`lab33-docker-image-trivy-scan/`)
- Kiểm thử an ninh container chuyên sâu: bóc tách và soi chiếu từng layer của Docker Image bằng Trivy.
- Phân biệt lỗ hổng hệ điều hành nền (OS Packages) và lỗ hổng gói mã nguồn thư viện ứng dụng (Language Packages).
- Phát hiện các sai sót cấu hình (Misconfiguration) trong Dockerfile: chạy quyền Root, gắn tag bất biến, rò rỉ file mật.
- Tái cấu trúc Dockerfile Multi-stage với Non-root user để triệt tiêu CVE và cấu hình `.trivyignore` có kiểm soát.

### Lab 34: Ký Số Và Xác Thực Docker Image Với Cosign (`lab34-docker-image-signing-cosign/`)
- Xây dựng chuỗi cung ứng phần mềm an toàn (Software Supply Chain Security) bằng công cụ Sigstore Cosign.
- Khởi tạo kho lưu trữ OCI Registry cục bộ và tạo cặp khóa mật mã bất đối xứng (Public/Private Keypair).
- Thực thi ký số Cryptographic Digest của Image và xác thực chữ ký trước khi triển khai (Pre-deployment Verification).
- Mô phỏng và ngăn chặn các cuộc tấn công đánh tráo Image (Tampering Attack) và đính kèm SBOM trực tiếp vào Image Manifest.

### Lab 35: Instrument Ứng Dụng Để Thu Thập Metrics (`lab35-app-metrics-instrumentation/`)
- Tiếp cận trụ cột đầu tiên của Observability (Metrics) và phương pháp giám sát RED (Rate, Errors, Duration).
- Tích hợp thư viện `prom-client` vào ứng dụng backend, xây dựng các loại metric chuẩn: Counter, Gauge, Histogram.
- Expose endpoint chuẩn hóa `/metrics`, khởi chạy máy chủ Prometheus và cấu hình Scrape Target định kỳ.
- Sinh tải tự động và thực thi các câu truy vấn PromQL phân tích hiệu năng: tỷ lệ lỗi 5xx, throughput và độ trễ p95/p99.

### Lab 36: Thu Thập Metrics Và Logs Từ Hạ Tầng (`lab36-infra-metrics-logs/`)
- Xây dựng hệ thống quan sát hạ tầng máy chủ toàn diện kết hợp giữa Metrics và Logs.
- Triển khai Prometheus Node Exporter thu thập chỉ số phần cứng và Linux Kernel (CPU, Memory, Disk I/O, Network).
- Triển khai cụm lưu trữ nhật ký tập trung Grafana Loki kết hợp Promtail Shipper thu thập logs hệ thống (`/var/log`).
- Mô phỏng các sự kiện hạ tầng thực tế và viết truy vấn phân tích, lọc lỗi chuyên sâu bằng ngôn ngữ LogQL.

### Lab 37: Xây Dựng Hệ Thống Centralized Logging (`lab37-centralized-logging/`)
- Thiết kế Pipeline xử lý nhật ký tập trung chuẩn CNCF với Fluent Bit và Grafana Loki.
- Cấu hình Parser bóc tách đa định dạng: cấu trúc hóa log ứng dụng JSON và Nginx Combined Log dạng regex.
- Áp dụng Filter làm giàu metadata hạ tầng (environment, cluster) và che dấu dữ liệu nhạy cảm (Data Masking).
- Thiết lập định tuyến theo nhãn (Tag-based Routing) về Loki và thực hiện truy vết giao dịch xuyên tầng bằng LogQL.

### Lab 38: Instrument Và Trace Một Request (`lab38-instrument-trace-request/`)
- Làm chủ kỹ thuật Distributed Tracing chuẩn OpenTelemetry trên kiến trúc Microservices phân tán.
- Triển khai Jaeger All-in-One làm backend thu thập và trực quan hóa trace tập trung.
- Tích hợp OpenTelemetry SDK thu thập in-process spans và thực hiện Context Propagation qua chuẩn W3C Trace Context (`traceparent`).
- Mô phỏng sự cố trễ và exception, phân tích biểu đồ Waterfall trên Jaeger UI để cô lập chính xác nút thắt cổ chai.

### Lab 39: [Case Study] Phân Tích Nguyên Nhân Gốc Rễ — Root Cause Analysis (`lab39-root-cause-analysis/`)
- Đóng vai SRE On-Call trực tiếp vào hiện trường xử lý sự cố P1 Incident (Checkout API bị timeout 504 và sập tỷ lệ thanh toán).
- Áp dụng chu trình điều tra sự cố khoa học 4 bước: Triage hiện trường, Pinpoint bằng Tracing, Root Cause bằng Logging, Mitigate & Post-Mortem.
- Kết hợp Jaeger cô lập dịch vụ nghẽn và Grafana Loki LogQL bắt trọn exception `ConnectionPoolExhaustedError` do cấu hình `DB_POOL_MAX=2`.
- Tiến hành Hotfix cứu hệ thống, xác thực phục hồi 100% bằng load test và lập báo cáo sự cố chuẩn mực 5-Whys.

### Lab 40: Cấu Hình Prometheus Và Exporters (`lab40-prometheus-exporters/`)
- Làm chủ kiến trúc giám sát Pull-based, nguyên lý hoạt động của Prometheus Retrieval Engine và các chuẩn định dạng OpenMetrics.
- Triển khai Node Exporter thu thập toàn diện chỉ số hạt nhân Linux Kernel (CPU, Memory, Disk, Network) tại cổng `9100`.
- Triển khai Redis Exporter kết nối cơ sở dữ liệu Redis tại cổng `9121`, khảo sát chuyển đổi thông số nội bộ thành OpenMetrics.
- Thiết kế tệp cấu hình `prometheus.yml` thu thập đa nguồn, làm giàu nhãn quản trị (Metadata Labels) và làm chủ kỹ thuật Hot-reload (`/-/reload`) Zero-downtime.

### Lab 41: Phân Tích Hệ Thống Bằng PromQL (`lab41-promql-system-analysis/`)
- Phân biệt Instant Vector và Range Vector, làm chủ 4 bộ lọc nhãn (`=`, `!=`, `=~`, `!~`) với biểu thức chính quy Regex.
- Nắm vững công thức kinh điển tính % CPU Usage thực tế từ metric Counter và % RAM tiêu thụ từ metric Gauge.
- Đo lường và đánh giá SLA/SLO ứng dụng theo phương pháp RED: tính Throughput (RPS), Tỷ lệ lỗi % 5xx và độ trễ p95 bằng hàm `histogram_quantile`.
- Thiết lập biểu thức lọc ngưỡng cảnh báo (Alert Expressions) và xếp hạng nút thắt lưu lượng bằng hàm `topk`.

### Lab 42: Xây Dựng Monitoring Dashboard (`lab42-monitoring-dashboard/`)
- Áp dụng triệt để tư duy Dashboard as Code: tự động hóa cấu hình Prometheus Data Source và Dashboards thông qua cơ chế Provisioning YAML.
- Thiết kế bộ chỉ số hạ tầng Linux trực quan với các Panel: đồng hồ Gauge đo % CPU/RAM và biểu đồ Time-series lưu lượng mạng.
- Xây dựng bảng điều khiển giám sát Microservices theo mô hình RED: đo lường thông lượng theo endpoint, tỷ lệ lỗi 5xx và độ trễ p95 SLA.
- Làm chủ kỹ thuật Dynamic Templating (Variables): tạo bộ lọc Dropdown bằng hàm `label_values()` giúp người dùng lọc số liệu linh hoạt theo từng API endpoint.

### Lab 43: Thiết Lập Cảnh Báo (Alerting) (`lab43-prometheus-alertmanager/`)
- Thiết kế các quy tắc cảnh báo (Alerting Rules) chuẩn SRE bằng PromQL cho hạ tầng (CPU/RAM/Target Down) và ứng dụng (Tỷ lệ lỗi 5xx), kiểm thử cú pháp với `promtool`.
- Triển khai và cấu hình Alertmanager: làm chủ cây định tuyến (Routing Tree), gom cụm cảnh báo bằng `group_by`, kiểm soát tần suất thông báo với `group_wait`, `group_interval` và `repeat_interval`.
- Kỹ thuật phòng chống "Bão cảnh báo" (Alert Fatigue): áp dụng Inhibition Rules kìm hãm cảnh báo con khi cảnh báo gốc bùng phát và quản lý thời gian bảo trì (Silences) bằng `amtool`.
- Thực chiến mô phỏng sự cố bằng Fault Injection, theo dõi vòng đời `Pending` -> `Firing` -> `Resolved` và kiểm chứng gói tin Webhook JSON.

### Lab 44: Xây Dựng Kịch Bản Load & Stress Testing (`lab44-load-stress-testing/`)
- Khởi tạo kịch bản kiểm thử tải Baseline với công cụ k6 (Testing as Code), đo lường Throughput (RPS), Latency phân vị (`p90`, `p95`, `p99`) và Error Rate.
- Thiết lập kịch bản Stress Test đa giai đoạn (Ramping Stages) với cấu hình `stages` tăng dần từ 20 -> 50 -> 90 VUs để xác định điểm gãy (Breaking Point) của dịch vụ.
- Đánh giá khả năng tự phục hồi (Self-healing) của hệ thống khi lượng truy cập hạ nhiệt (Ramp-down).
- Tích hợp cơ chế Thresholds tự động (Pass/Fail criteria), biến kịch bản k6 thành cổng kiểm soát chất lượng (Quality Gate) chặn mã nguồn kém hiệu năng trong pipeline CI/CD.

### Lab 45: Correlate Load Test Với Monitoring (`lab45-load-test-monitoring/`)
- Xây dựng kiến trúc thu thập dữ liệu tải thời gian thực giữa ứng dụng mục tiêu, Prometheus (chu kỳ scrape 2s) và Grafana Dashboard.
- Thực thi tải nền từ k6 kết hợp quan sát song song các đồ thị Throughput, Latency, Active Connections và CPU Utilization trên Grafana.
- Kích hoạt tải đột biến (Spike) chạm ngưỡng bão hòa để thực hành kỹ năng đối chiếu (Correlation): phát hiện CPU vượt 85% kéo theo độ trễ tăng vọt và phát sinh lỗi 503 do cạn kiệt Worker Thread Pool.
- Hoạch định năng lực (Capacity Planning): xác định 3 vùng tải (An toàn, Cảnh báo, Điểm gãy) và xuất báo cáo kiến trúc đề xuất giải pháp HPA và Hàng đợi bất đồng bộ.

---



## 3. Cấu Trúc File Chuẩn Của Mỗi Bài Lab

Mỗi thư mục bài lab được tổ chức theo tiêu chuẩn kịch bản của Killercoda:

```text
labX-ten-bai-lab/
├── index.json          # File cấu hình metadata kịch bản (tiêu đề, thời lượng, các bước)
├── background.sh       # Script chạy ngầm khởi tạo môi trường (Docker, package, cấu hình)
├── foreground.sh       # Script đồng bộ giao diện hiển thị trạng thái chờ môi trường
├── intro.md            # Trang giới thiệu bài học, sơ đồ kiến trúc và mục tiêu
├── step1.md            # Hướng dẫn lý thuyết và thử thách thực hành Bước 1
├── step1-verify.sh     # Script tự động kiểm tra và chấm điểm Bước 1
├── step2.md            # Hướng dẫn lý thuyết và thử thách thực hành Bước 2
├── step2-verify.sh     # Script tự động kiểm tra và chấm điểm Bước 2
├── step3.md            # Hướng dẫn lý thuyết và thử thách thực hành Bước 3
├── step3-verify.sh     # Script tự động kiểm tra và chấm điểm Bước 3
├── finish.md           # Trang chúc mừng, bảng tra cứu nhanh lệnh (Cheat Sheet)
└── architecture.svg    # (Tùy chọn) Sơ đồ kiến trúc vector trực quan
```

---

## 4. Hướng Dẫn Tích Hợp Và Chạy Trên Killercoda

1. Đăng ký tài khoản trên [Killercoda](https://killercoda.com/) và kích hoạt chế độ **Creator**.
2. Kết nối tài khoản GitHub chứa repository này với Killercoda.
3. Tạo cấu trúc thư mục scenario hoặc để Killercoda đồng bộ tự động từ các thư mục `lab*`.
4. Mỗi bài lab có thời lượng khuyến nghị là **35-40 phút** trên nền tảng Ubuntu 22.04 LTS.

---

## 5. Quy Chuẩn Kỹ Thuật

- **Ngôn ngữ**: Toàn bộ tài liệu hướng dẫn được biên soạn bằng tiếng Việt có dấu chuẩn xác.
- **Phương pháp tiếp cận**: Thực hành chủ động (DIY - Do It Yourself) không dùng thẻ thực thi tự động ở phần thử thách để học viên rèn luyện kỹ năng gõ lệnh trên terminal.
- **Độ tin cậy**: Tất cả script shell đều được kiểm định cú pháp nghiêm ngặt (`bash -n`) và kiểm tra tính hợp lệ JSON (`jq`).
