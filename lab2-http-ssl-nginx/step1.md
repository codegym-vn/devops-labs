# Buoc 1: Phan Tich Giao Thuc HTTP - Request, Response & Headers

Giao thuc **HTTP (HyperText Transfer Protocol)** la nen tang giao tiep cua World Wide Web va cung la giao thuc chinh ma cac API, Webhook, Container Registry su dung trong he thong DevOps. Truoc khi hieu HTTPS, ban can nam vung cach HTTP hoat dong.

> **Luu y moi truong:** He thong Killercoda da tu dong cai dat san `nginx`, `openssl` va `curl` o che do nen. Ban co the bat dau go lenh ngay.

---

## 1. Cau Truc Mot HTTP Request

Khi ban go `curl http://example.com`, trinh khach (client) gui mot **HTTP Request** co cau truc:

```text
GET / HTTP/1.1                    <-- Request Line: Method + Path + HTTP Version
Host: example.com                 <-- Header: Ten mien dich
User-Agent: curl/7.68.0          <-- Header: Phan mem gui request
Accept: */*                       <-- Header: Loai noi dung chap nhan
                                  <-- Dong trong: Ket thuc phan Header
                                  <-- Body (neu co, voi POST/PUT)
```

### Cac HTTP Method quan trong cho DevOps

| Method | Muc Dich | Vi Du Thuc Te |
|---|---|---|
| **GET** | Lay du lieu | `curl http://api.example.com/health` — Health check |
| **POST** | Gui du lieu tao moi | Webhook CI/CD gui thong bao build |
| **PUT** | Cap nhat toan bo tai nguyen | Update cau hinh qua API |
| **DELETE** | Xoa tai nguyen | Xoa container/pod qua API |
| **HEAD** | Lay header (khong co body) | Kiem tra nhanh server co song khong |

---

## 2. Cau Truc HTTP Response va Status Code

Server tra ve mot **HTTP Response** bao gom:

```text
HTTP/1.1 200 OK                   <-- Status Line: Version + Status Code + Reason
Content-Type: text/html           <-- Header: Loai noi dung tra ve
Content-Length: 1256              <-- Header: Kich thuoc body (bytes)
Connection: keep-alive            <-- Header: Giu ket noi TCP
                                  <-- Dong trong
<!doctype html>...                <-- Body: Noi dung trang web/API
```

### Cac Nhom Status Code Quan Trong Cho DevOps

| Nhom | Y Nghia | Ma Thuong Gap | Ngu Canh DevOps |
|---|---|---|---|
| **2xx** | Thanh cong | `200 OK`, `201 Created`, `204 No Content` | API tra ve du lieu thanh cong, resource duoc tao |
| **3xx** | Chuyen huong | `301 Moved Permanently`, `302 Found`, `304 Not Modified` | HTTP redirect sang HTTPS, CDN cache |
| **4xx** | Loi phia Client | `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` | API key sai, endpoint khong ton tai |
| **5xx** | Loi phia Server | `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout` | Backend crash, Nginx khong ket noi duoc backend |

> **Meo debug cho DevOps:** Khi gap loi `502 Bad Gateway`, van de thuong nam o **ket noi giua Nginx va backend** (backend chua chay, port sai, hoac process bi crash). Khi gap `504 Gateway Timeout`, backend dang **xu ly qua lau** vuot qua `proxy_read_timeout`.

---

## 3. Thuc Hanh: Phan Tich HTTP Voi `curl -v`

Tham so `-v` (verbose) cua `curl` cho phep ban quan sat **toan bo qua trinh giao tiep HTTP**: tu bat tay TCP, gui request, den nhan response.

### Gui request toi mot website thuc te

```bash
curl -v -s -o /dev/null http://example.com
```{{exec}}

Hay phan tich output:
- Dong bat dau bang `>` la du lieu **client gui di** (Request).
- Dong bat dau bang `<` la du lieu **server tra ve** (Response).
- Dong bat dau bang `*` la thong tin ket noi (TCP handshake, DNS resolution).

### Chi xem Response Headers (khong tai body)

Lenh `curl -I` (hoac `--head`) gui request bang method `HEAD` de chi lay headers:

```bash
curl -I http://example.com
```{{exec}}

Quan sat cac header quan trong:
- `Content-Type`: Dinh dang noi dung tra ve (`text/html`, `application/json`).
- `Content-Length`: Kich thuoc body tinh bang bytes.
- `Server`: Phan mem web server dang chay (Nginx, Apache, Cloudflare).
- `Cache-Control`: Chinh sach cache (quan trong cho CDN va browser caching).

### Gui POST request voi du lieu JSON

Trong CI/CD, cac Webhook thuong gui du lieu bang POST. Hay mo phong voi mot public API:

```bash
curl -v -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"service": "payment", "status": "healthy"}'
```{{exec}}

Quan sat:
- Method chuyen tu `GET` sang `POST`.
- Header `Content-Type: application/json` bao server du lieu la JSON.
- Body request chua payload JSON.

---

## 4. HTTP Headers Quan Trong Trong Ha Tang DevOps

| Header | Huong | Muc Dich | Vi Du |
|---|---|---|---|
| `Host` | Request | Xac dinh ten mien dich (bat buoc tu HTTP/1.1) | `Host: api.example.com` |
| `Content-Type` | Ca hai | Loai noi dung (MIME type) | `application/json`, `text/html` |
| `Authorization` | Request | Xac thuc danh tinh client | `Bearer <token>`, `Basic <base64>` |
| `User-Agent` | Request | Dinh danh phan mem client | `curl/7.68.0`, `Mozilla/5.0` |
| `X-Real-IP` | Request (Proxy) | IP that cua client (do Reverse Proxy them vao) | `X-Real-IP: 203.0.113.50` |
| `X-Forwarded-For` | Request (Proxy) | Chuoi IP ma request da di qua | `client, proxy1, proxy2` |
| `X-Forwarded-Proto` | Request (Proxy) | Giao thuc goc cua client (http hoac https) | `X-Forwarded-Proto: https` |
| `Cache-Control` | Response | Chinh sach cache cho CDN va browser | `max-age=3600`, `no-cache` |
| `Set-Cookie` | Response | Thiet lap cookie phia client | Session ID, CSRF token |

---

## 5. Thu Thach & Xac Thuc (Verification)

Hay su dung `curl` de lay **HTTP status code** cua trang `http://example.com`:

1. Tim lenh `curl` phu hop de chi xuat ra **duy nhat ma so status code** (vi du: `200`, `301`, `404`).

<details>
<summary>Xem goi y</summary>

- Tham so `-o /dev/null` bo qua body response.
- Tham so `-s` tat thanh tien trinh (silent mode).
- Tham so `-w` cho phep dinh dang output tuy chinh, vi du `"%{http_code}"` chi xuat status code.
</details>

2. Khi da tim duoc lenh phu hop, hay **tu tay go lenh** tren terminal de luu ket qua vao file (thay the `<STATUS_CODE>` bang gia tri thuc te):
   ```bash
   echo "<STATUS_CODE>" > /tmp/http_status.txt
   ```
   *(Vi du: neu status code la 200, hay go `echo "200" > /tmp/http_status.txt`)*

3. Bam nut **Check** ben duoi thanh dieu khien de he thong tu dong cham diem!
