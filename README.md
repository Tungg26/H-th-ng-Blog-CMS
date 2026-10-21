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

- `docker-compose.yml`: MySQL, WordPress, phpMyAdmin và Nginx.
- `nginx/nginx.conf`: reverse proxy HTTP sang HTTPS, WordPress và phpMyAdmin.
- `nginx/certs/`: chứng thư TLS công khai; khóa riêng `cert.key` không được đưa
  lên Git.
- `monitoring/`: vị trí các cấu hình Prometheus và Promtail. Hai file hiện đang
  để trống và chưa được kết nối với service nào trong Docker Compose.
- `.env.example`: mẫu biến môi trường; không chứa mật khẩu thật.

## Chạy trên máy cá nhân

Cần cài Docker Desktop (bao gồm Docker Compose) và OpenSSL.

1. Tạo file biến môi trường từ mẫu:

   ```powershell
   Copy-Item .env.example .env
   ```

   Sửa các giá trị mật khẩu trong `.env`. Không commit file này.

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