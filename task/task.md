# Kế hoạch triển khai: Giao hàng theo Món (Item-Level Delivery)

Danh sách các tác vụ cần thực hiện để hoàn thiện luồng giao hàng theo từng phần/món, cho phép gom chuyến động.

- [ ] **Bước 1: Cấu trúc Database**
  - Chỉnh sửa cơ chế thêm vào `chitietdonhang` lúc Checkout: Nếu số lượng > 1, tự động tách thành N dòng (mỗi dòng số lượng = 1) để bếp thao tác từng phần.
  - Thêm cột `maNhomGiaoHang` vào bảng `chitietdonhang` (để quản lý chuyến đi giao theo từng phần ăn).

- [ ] **Bước 2: Cập nhật Màn hình KDS (Prepare) (Frontend + Backend)**
  - **Frontend:** Xây dựng UI Lớp Cha - Lớp Con. Gộp các `chitietdonhang` giống nhau thành Thẻ Cha. Click mở rộng thành các Thẻ Con.
  - **Frontend:** Cho phép quẹt/nhấn hoàn thành từng Thẻ Con độc lập.
  - **Backend:** Cập nhật hàm `markKDSItemReady`: Khi kéo Thẻ Con, chỉ cập nhật `trangThaiMon = 'ready'`. Không cập nhật trạng thái `donhang` ngay lập tức nếu chưa giao.  
- [ ] **Bước 3: Tái cấu trúc Giao diện & Tab Giao Hàng (Frontend + Backend)**
  - **Đồng bộ Layout Bottom Navigation:** Biến Tab "Menu" ở giữa thành nút tròn nổi bật (giống nút Home của app khách hàng).
  - **Di chuyển tính năng cũ:** Thêm icon `...` (More) góc trên phải màn hình "Menu". Di chuyển "Store Information" và "Quản lý Voucher" vào menu này.
  - **Đổi Tab dưới cùng:** Đổi tên Tab "More" dưới cùng thành Tab "Ship" (Giao hàng) kèm đổi icon.
  - **Giao diện Tab Ship:** Xây dựng màn hình hiển thị danh sách các món `ready` (chờ giao).
  - **Backend APIs:**
    - `getReadyItems(maGianHang)`: Lấy các món đang `ready`.
    - `startDeliveryTrip(danhSachMaChiTiet)`: Tạo `nhomgiaohang` mới (Chuyến đi giao), cập nhật trạng thái các món thành `delivering`.
    - `completeTrip(maNhomGiaoHang)`: Hoàn tất chuyến đi, cập nhật trạng thái món thành `delivered`.
  - **Frontend (Tương tác):**
    - Nút bấm "Bắt đầu đi giao" gọi API `startDeliveryTrip`.
    - Màn hình "Chuyến giao hàng hiện tại" với nút "Hoàn tất".

- [ ] **Bước 4: Đồng bộ trạng thái Đơn hàng (`donhang`)**
  - Viết logic cập nhật trạng thái phái sinh: Nếu 1 món trong đơn đang `delivering` thì `donhang` -> `dangGiao`. Nếu tất cả món `delivered` -> `donhang` -> `daGiao`.

- [ ] **Bước 5: Cập nhật App Khách hàng**
  - Khách hàng có thể thấy chi tiết trạng thái từng món trong đơn của mình (Món A: Đang giao, Món B: Đang nấu).
  - Tắt CronJob tự động gom đơn.

---

# Kế hoạch triển khai: Module Admin (Quản trị hệ thống)

- [ ] **Bước 1: Chuẩn bị Database (Backend)**
  - Thêm cột `trangThai` (active/banned) vào bảng `taikhoan`.
  - Thêm cột `trangThai` vào bảng `gianhang`.
  - Cấu trúc lại bảng `promotions` để hỗ trợ Voucher cấp Admin và Voucher cấp Gian hàng.

- [ ] **Bước 2: Xây dựng Admin APIs (Backend)**
  - Middleware bảo mật: `authorizeRole([3])`.
  - API Quản lý Căn tin: `GET/POST/PUT /api/admin/stores`.
  - API Quản lý Tài khoản: `GET/PUT /api/admin/users`.
  - API Quản lý Voucher: `GET/POST/PUT /api/admin/vouchers`.

- [ ] **Bước 3: Dựng Giao diện Admin (Frontend)**
  - Dựng khung Layout Admin (có Sidebar hoặc Bottom Navigation riêng cho role 3).
  - Xây dựng màn hình Dashboard tổng quan.
  - Xây dựng màn hình Quản lý Gian hàng (hiển thị danh sách, thêm/sửa/xóa/đóng cửa).
  - Xây dựng màn hình Quản lý Tài khoản (phân quyền, khóa/mở khóa tài khoản).
  - Xây dựng màn hình Quản lý Voucher (tạo voucher mới, thiết lập điều kiện).

- [ ] **Bước 4: Tích hợp Đăng nhập (Frontend)**
  - Điều hướng người dùng: Nếu `role == 3`, chuyển thẳng vào `AdminDashboardView` thay vì màn hình khách hàng.
