# Hệ thống Blog / CMS

Website blog/CMS được xây dựng bằng WordPress, triển khai với MySQL, phpMyAdmin
và Nginx. Repository được đặt theo mã số sinh viên `20230001`.

## Chức năng CMS

- Soạn, chỉnh sửa, xuất bản và quản lý bài viết.
- Tạo và gán danh mục cho bài viết.
- Quản lý người dùng WordPress theo vai trò như Administrator, Editor, Author
  và Contributor.
- MySQL lưu dữ liệu website; phpMyAdmin cung cấp giao diện quản lý database.

## Thiết lập lần đầu

Stack đã triển khai sẽ hiển thị trang cài đặt WordPress. Mở
`https://localhost:8448`, chọn ngôn ngữ, đặt tên website và tự tạo tài khoản
quản trị. Sau khi cài đặt:

- Trang blog: `https://localhost:8448/`
- Trang quản trị bài viết, danh mục và người dùng:
  `https://localhost:8448/wp-admin/`
- Trình quản lý database: `https://localhost:8448/pma/`

Tự đặt và lưu an toàn thông tin đăng nhập quản trị; không đưa mật khẩu vào Git.

## Thành phần

- `docker-compose.yml`: MySQL, WordPress 7.1.3, phpMyAdmin, Nginx, Prometheus,
  Grafana 13.2.2, Loki, Promtail và exporters.
- `nginx/nginx.conf`: reverse proxy HTTP sang HTTPS, WordPress và phpMyAdmin.
- `nginx/certs/`: chứng thư TLS công khai; khóa riêng `cert.key` không được đưa
  lên Git.
- Nginx giới hạn TLS ở phiên bản 1.2/1.3, ẩn phiên bản server và thêm các
  security headers cơ bản. Chứng thư tự ký chỉ dành cho môi trường local.
- MySQL root và application passwords trên máy triển khai đã được xoay sang hai
  secret ngẫu nhiên 64 ký tự hex riêng biệt; chúng chỉ nằm trong `.env` bị
  ignore và không được chia sẻ/commit.
- Nginx, exporters, Prometheus, Grafana và Loki chạy non-root, filesystem
  read-only, bỏ capabilities và bật `no-new-privileges`. Backend database là
  network nội bộ, không publish cổng MySQL ra host.
- WordPress, phpMyAdmin và MySQL dùng entrypoint của image upstream để khởi
  tạo dữ liệu rồi hạ quyền tiến trình ứng dụng; không ép UID cho các container
  này để tránh phá quyền volume. Promtail cần quyền root trong container để đọc
  Docker socket; cAdvisor cần privileged để thu thập metrics. Đây là các quyền
  đặc biệt chỉ dành cho monitoring, không cấp cho Nginx/WordPress.
- `monitoring/`: cấu hình Prometheus, Grafana datasource/dashboard, Loki và
  Promtail.
- Các exporter, Prometheus, Grafana, Loki và Nginx chạy non-root với filesystem
  read-only, chỉ cấp volume/tmpfs để ghi dữ liệu cần thiết, bỏ Linux
  capabilities và bật `no-new-privileges`. MySQL và WordPress dùng image
  upstream có entrypoint cần khởi chạy bằng root để khởi tạo rồi hạ quyền tiến
  trình ứng dụng; không áp đặt UID thủ công để tránh làm hỏng volume/entrypoint.
  Grafana tắt cài plugin tự động vì Prometheus/Loki đã được provision và image
  chạy với root filesystem chỉ đọc.
- Promtail cần quyền root trong container để đọc Docker socket; quyền với socket
  tương đương quyền quản trị Docker. cAdvisor cần quyền privileged để đọc
  metrics container. Hai ngoại lệ này được giữ ở phạm vi monitoring và không
  cấp socket/privileged cho ứng dụng web.
- cAdvisor theo dõi tài nguyên container; Nginx Prometheus Exporter thu thập
  trạng thái web server; MySQL Exporter thu thập metrics database bằng tài
  khoản ứng dụng với quyền metrics cần thiết, không dùng tài khoản root.
- `.env.example`: mẫu biến môi trường; không chứa mật khẩu thật.

## Chạy trên máy cá nhân

Cần cài Docker Desktop (bao gồm Docker Compose) và OpenSSL.

WordPress và Grafana được ghim theo phiên bản trong `docker-compose.yml` để
triển khai có thể lặp lại. Khi nâng cấp WordPress, sao lưu database và
`wordpress_data` trước; image WordPress dùng volume này cho mã nguồn và nội dung.

1. Tạo file biến môi trường từ mẫu:

   ```powershell
   Copy-Item .env.example .env
   $rootSecret = openssl rand -hex 32
   $appSecret = openssl rand -hex 32
   $envText = (Get-Content .env -Raw).Replace(
     'replace_with_a_unique_64_character_hex_secret', $rootSecret
   ).Replace(
     'replace_with_a_different_unique_64_character_hex_secret', $appSecret
   )
   [System.IO.File]::WriteAllText(
     (Resolve-Path .env), $envText, [System.Text.UTF8Encoding]::new($false)
   )
   ```

   Mỗi password cần là một giá trị hex ngẫu nhiên 64 ký tự khác nhau. Nếu dùng giá
   trị riêng, tránh dấu nháy, dấu `$` và dấu `#` trong mật khẩu để không bị diễn
   giải bởi Compose. `.env` không được commit.

2. Tạo khóa riêng và chứng thư TLS tự ký cho `localhost` (không dùng chứng thư
   này cho môi trường production):

   ```powershell
   New-Item -ItemType Directory -Force nginx/certs | Out-Null
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
     -keyout nginx/certs/cert.key `
     -out nginx/certs/cert.crt `
     -subj "/CN=localhost"
   ```

   `nginx/certs/cert.key` đã được thêm vào `.gitignore`. Không chia sẻ khóa riêng.
   Nginx dùng cổng `8088` và `8448` trên máy host để tránh xung đột với dịch vụ
   khác đang sử dụng cổng HTTP/HTTPS mặc định.

3. Khởi động các dịch vụ:

   ```powershell
   docker compose up -d
   ```

   Truy cập trang cài đặt WordPress tại `https://localhost:8448` và phpMyAdmin
   tại `https://localhost:8448/pma/`. HTTP tại `http://localhost:8088` sẽ chuyển
   sang HTTPS. Trình duyệt có thể cần xác nhận cảnh báo do chứng thư tự ký.

- Mở Grafana tại `http://localhost:3001`, đăng nhập mặc định lần đầu bằng
  `admin` / `admin` và đổi mật khẩu ngay sau khi đăng nhập. Dashboard **Blog CMS
  Overview** được nạp sẵn.
- Mở Prometheus tại `http://localhost:9091` để xem trạng thái scrape targets.
  Cả hai giao diện giám sát chỉ bind vào localhost; không công khai trực tiếp
  lên mạng.
- Dashboard giám sát gồm CPU/RAM container, kết nối Nginx, số kết nối MySQL và
  trạng thái các scrape targets. Script `monitoring/mysql-exporter-init.sh`
  cấp các quyền đọc metrics cho tài khoản MySQL ứng dụng ở lần khởi tạo database
  mới.
- Loki lưu log 7 ngày trong Docker volume; Promtail dùng Docker socket để thu
  log container thuộc Compose project này. Quyền đọc Docker socket có thể cấp
  quyền quản trị Docker, vì vậy chỉ chạy stack này trên máy đáng tin cậy.
- Trong Grafana Explore, chọn datasource **Loki** và thử các truy vấn LogQL:

  ```logql
  {service="wordpress"}
  {service="nginx"}
  {service="nginx"} |= "error"
  ```

  Loki API cục bộ (chỉ bind vào localhost): `http://localhost:3101`.

Nếu đang nâng cấp một database volume đã khởi tạo trước khi bật MySQL Exporter,
chạy một lần lệnh sau bằng tài khoản MySQL root (thay `wordpress` bằng giá trị
`MYSQL_USER` trong `.env`):

```sql
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'wordpress'@'%';
```

4. Dừng các dịch vụ khi không sử dụng:

   ```powershell
   docker compose down
   ```

## GitHub và commit

Tạo tài khoản GitHub theo quy định của trường; nếu còn tên, dùng `20230001` làm
username hoặc tên hiển thị theo hướng dẫn của trường. GitHub không đảm bảo tên
người dùng đó còn trống. Tạo repository công khai/riêng tên `20230001` (không
tạo README từ GitHub vì README đã có trong repository này).

Đặt tên tác giả commit theo yêu cầu của dự án. Repository này hiện dùng tên
`Hệ thống` và email noreply của GitHub:

```powershell
git config user.name "Hệ thống"
git config user.email "Tungg26@users.noreply.github.com"
git add .
git status
git commit -m "Describe the change"
git push -u origin main
```

Trước mỗi commit, xem `git status` để xác nhận `.env` và
`nginx/certs/cert.key` không nằm trong danh sách staged. Không đưa mật khẩu,
token, khóa riêng hoặc thông tin đăng nhập vào GitHub.