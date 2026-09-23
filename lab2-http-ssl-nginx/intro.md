Chao mung ban den voi bai lab **HTTP/HTTPS & SSL/TLS Certificates Cho Nginx**.

Trong he sinh thai DevOps hien dai, **moi giao tiep giua cac dich vu** (API Gateway, Microservices, CI/CD Webhook, Container Registry) deu di qua giao thuc **HTTP** hoac **HTTPS**. Hieu ro cach mot HTTP request duoc gui di, phan hoi tra ve nhu the nao, va tai sao can ma hoa bang TLS la ky nang thiet yeu de debug, toi uu va bao mat ha tang.

---

## Tai Sao DevOps Engineer Can Hieu HTTP/HTTPS?

- **Debug loi 502 Bad Gateway, 504 Gateway Timeout**: Can doc duoc HTTP status code va headers de xac dinh loi o tang nao (Nginx, backend, hay mang).
- **Cau hinh SSL/TLS cho domain**: Moi ung dung production deu yeu cau HTTPS. Ban can biet cach tao, cai dat va gia han certificate.
- **SSL Termination tai Reverse Proxy**: Nginx giai ma TLS roi chuyen tiep HTTP thuan toi backend, giup giam tai va tap trung quan ly certificate.

---

## So Sanh HTTP vs HTTPS

| Dac Tinh | HTTP | HTTPS |
|---|---|---|
| **Cong mac dinh** | 80 | 443 |
| **Ma hoa du lieu** | Khong — du lieu truyen duoi dang plaintext | Co — ma hoa bang TLS/SSL |
| **Xac thuc server** | Khong — khong kiem tra danh tinh server | Co — server xuat trinh Certificate |
| **Toan ven du lieu** | Khong dam bao — du lieu co the bi sua doi giua duong | Dam bao — moi thay doi deu bi phat hien |
| **Ung dung** | Moi truong noi bo, dev/test | Production, API public, moi he thong co du lieu nhay cam |

---

## Kien Truc Tong Quan Bai Lab

```text
                    Buoc 1: HTTP                  Buoc 3: HTTPS (TLS)
    Client  ───── Port 80 (plaintext) ─────>  [ Nginx ]
  (curl/browser)                                  │
                ───── Port 443 (encrypted) ──>  [ Nginx + SSL Certificate ]
                                                  │
                    Buoc 2: Kiem tra              (SSL Termination)
                    Certificate thuc te            │
                    bang openssl s_client          ▼
                                              [ Backend ]
```

---

## Muc Tieu Bai Hoc

Sau khi hoan thanh bai thuc hanh nay, ban se:
1. **Phan tich duoc luong HTTP Request/Response** chi tiet bang `curl -v`: method, status code, headers.
2. **Hieu co che bat tay TLS (TLS Handshake)** va tai sao HTTPS bao ve du lieu tren duong truyen.
3. **Kiem tra Certificate thuc te** cua website bang `openssl s_client`: Subject, Issuer, ngay het han, certificate chain.
4. **Tao Self-Signed Certificate** bang `openssl` cho moi truong dev/test.
5. **Cau hinh Nginx phuc vu HTTPS** tren cong 443 voi SSL/TLS.
6. **Thiet lap HTTP-to-HTTPS Redirect** tu dong chuyen huong traffic tu cong 80 sang 443.

---

## Tinh Nang Tuong Tac Tren Killercoda

- **Tu dong hoa moi truong (Background Initialization)**: Cac cong cu (`nginx`, `openssl`, `curl`) duoc he thong tu dong cai dat ngam.
- **Thuc thi lenh nhanh**: Bam truc tiep vao cac khoi lenh code tren huong dan de tu dong gui va chay lenh tren terminal.
- **Xac thuc tu dong (Verify Check)**: Moi buoc deu co phan **Thu Thach**. Sau khi hoan thanh, hay bam nut **Check** de he thong tu dong cham diem.

Bam **START** hoac chon **Buoc 1** de bat dau!
