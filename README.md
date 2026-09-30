# DevOps & Networking Labs

Kho lưu trữ mã nguồn các kịch bản thực hành tương tác (Interactive Scenarios) trên nền tảng **Killercoda**, được thiết kế chuyên sâu cho lộ trình đào tạo kỹ sư **DevOps, SRE và Cloud Systems**.

Tất cả các bài lab đều chạy trực tiếp trên môi trường ảo hóa Ubuntu, tích hợp cơ chế tự động hóa khởi tạo môi trường ngầm (Background Automation) và hệ thống script tự động chấm điểm (Automated Verification).

---

## 1. Danh Sách Các Bài Thực Hành

| Mã Lab | Thư Mục | Công Nghệ Chính | Trọng Tâm Kiến Thức | Thời Lượng |
|---|---|---|---|---|
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

---


## 2. Tóm Tắt Nội Dung Từng Bài Lab

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
