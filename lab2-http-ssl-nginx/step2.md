# Buoc 2: HTTPS & Bat Tay TLS - Kiem Tra Certificate Thuc Te

Trong buoc truoc, ban da thay HTTP truyen du lieu hoan toan duoi dang **plaintext** — bat ky ai nam giua duong truyen (man-in-the-middle) deu co the doc, sua doi noi dung. **HTTPS** giai quyet van de nay bang cach boc mot lop ma hoa **TLS (Transport Layer Security)** quanh giao thuc HTTP.

---

## 1. Ba Muc Tieu Bao Mat Cua HTTPS

| Muc Tieu | Giai Thich | Hau Qua Neu Thieu |
|---|---|---|
| **Ma hoa (Encryption)** | Du lieu duoc ma hoa tren duong truyen, chi client va server doc duoc | Hacker doc duoc password, API key, du lieu nhan cua nguoi dung |
| **Xac thuc (Authentication)** | Server xuat trinh Certificate de chung minh danh tinh | Client co the ket noi nhom vao server gia mao (phishing) |
| **Toan ven (Integrity)** | Moi thay doi du lieu tren duong truyen deu bi phat hien | Du lieu bi chen them ma doc hoac quang cao giua duong |

---

## 2. Quy Trinh Bat Tay TLS (TLS Handshake)

Truoc khi truyen bat ky du lieu HTTP nao qua HTTPS, client va server phai thuc hien **bat tay TLS** de thoa thuan khoa ma hoa:

```text
  Client                                    Server
    |                                         |
    | --- 1. ClientHello ------------------> |  Gui: TLS version, danh sach Cipher Suites
    |                                         |
    | <-- 2. ServerHello ------------------- |  Chon: Cipher Suite, gui Certificate
    |                                         |
    | --- 3. Xac minh Certificate ---------> |  Client kiem tra: CA hop le? Het han chua? Domain khop?
    |                                         |
    | --- 4. Key Exchange (Pre-Master) ----> |  Trao doi khoa bi mat de tao Session Key
    |                                         |
    | <-- 5. Finished ---------------------- |  Ca hai phia xac nhan san sang
    |                                         |
    | === Du lieu HTTP duoc ma hoa ========= |  GET /api/data HTTP/1.1 (encrypted)
```

> **Luu y:** TLS Handshake dien ra **sau** TCP 3-Way Handshake (da hoc o Lab 1, Buoc 2) va **truoc** khi bat ky du lieu HTTP nao duoc gui.

---

## 3. Chuoi Chung Chi (Certificate Chain)

Mot Certificate khong dung doc lap — no duoc xac thuc theo chuoi tin tuong (Chain of Trust):

```text
[Root CA Certificate]              Vi du: DigiCert Global Root G2
        |                          (Duoc cai san trong OS/Browser)
        v
[Intermediate CA Certificate]      Vi du: DigiCert SHA2 Extended Validation Server CA
        |                          (Cau noi giua Root va Leaf)
        v
[Leaf Certificate (Server)]        Vi du: CN=www.google.com
                                   (Certificate cua website/server)
```

- **Root CA**: Duoc OS va trinh duyet tin tuong san (pre-installed). Toan the gioi chi co khoang 150 Root CA.
- **Intermediate CA**: Tang bao mat bang cach khong dung Root CA truc tiep de ky.
- **Leaf Certificate**: Certificate cua website/domain cua ban.

---

## 4. Thuc Hanh: Kiem Tra Certificate Voi `openssl s_client`

Cong cu `openssl s_client` cho phep ban ket noi TLS truc tiep toi server va xem toan bo thong tin certificate.

### Ket noi va kiem tra certificate cua Google

```bash
echo | openssl s_client -connect google.com:443 -servername google.com 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

Giai thich cac truong:
- **subject**: Chu the so huu certificate (ten mien hoac to chuc).
- **issuer**: To chuc cap phat (Certificate Authority).
- **notBefore / notAfter**: Thoi gian hieu luc cua certificate.

### Xem toan bo chuoi certificate chain

```bash
echo | openssl s_client -connect google.com:443 -servername google.com -showcerts 2>/dev/null | grep -E "s:|i:" | head -10
```{{exec}}

Quan sat:
- `s:` (subject) — Chu the cua tung certificate trong chuoi.
- `i:` (issuer) — To chuc da ky (cap phat) certificate do.
- Thu tu: Leaf -> Intermediate -> Root.

### Kiem tra certificate cua mot domain khac

Thu voi GitHub:

```bash
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

### Kiem tra ngay het han cu the

Trong DevOps, kiem tra ngay het han certificate la tac vu monitoring quan trong de tranh su co mat HTTPS giua dem:

```bash
echo | openssl s_client -connect google.com:443 -servername google.com 2>/dev/null | openssl x509 -noout -enddate
```{{exec}}

---

## 5. Phan Biet Cac Loai Certificate

| Loai | Muc Dich | Gia | Su Dung |
|---|---|---|---|
| **Self-Signed** | Tu ky, khong co CA xac thuc | Mien phi | Dev/Test, moi truong noi bo |
| **Domain Validated (DV)** | CA xac minh quyen so huu domain | Mien phi (Let's Encrypt) | Website, API nho |
| **Organization Validated (OV)** | CA xac minh to chuc | Tra phi | Doanh nghiep, API noi bo |
| **Extended Validation (EV)** | Xac minh phap ly nghiem ngat | Tra phi cao | Ngan hang, tai chinh |
| **Wildcard** | Bao phu tat ca subdomain (`*.example.com`) | Tra phi | Nhieu subdomain cung domain chinh |

> **Trong thuc te DevOps:** Phan lon he thong su dung **Let's Encrypt (DV)** cho production va **Self-Signed** cho moi truong staging/dev. Buoc 3 se huong dan tao Self-Signed Certificate.

---

## 6. Quan Sat HTTPS Qua `curl -v`

So sanh voi HTTP o Buoc 1, hay xem them phan TLS handshake khi ket noi HTTPS:

```bash
curl -v -s -o /dev/null https://example.com 2>&1 | head -25
```{{exec}}

Chu y cac dong moi xuat hien so voi HTTP:
- `* TLSv1.3 (OUT), TLS handshake, Client hello` — Bat dau bat tay TLS.
- `* SSL connection using TLSv1.3 / ...` — Phien ban TLS va cipher suite da thoa thuan.
- `* Server certificate:` — Thong tin certificate cua server.
- `* subject:` va `* issuer:` — Chu the va to chuc cap phat.

---

## 7. Thu Thach & Xac Thuc (Verification)

Hay su dung `openssl s_client` de kiem tra certificate cua domain `github.com` tren cong `443`.

1. Trich xuat dong **subject** cua certificate (dong chua `subject=...`).
2. Khi da xac dinh duoc thong tin, hay **tu tay go lenh** tren terminal de luu ten to chuc (Organization) tu truong subject vao file:
   ```bash
   echo "<TEN_TO_CHUC>" > /tmp/cert_subject.txt
   ```
   *(Vi du: neu subject chua `O = GitHub, Inc.`, hay go `echo "GitHub, Inc." > /tmp/cert_subject.txt`)*

3. Bam nut **Check** ben duoi thanh dieu khien de he thong xac thuc ket qua!
