# Kế hoạch triển khai: Module Admin (Quản trị hệ thống)

Dựa trên sơ đồ Use Case tổng quát bạn cung cấp, Actor **Admin** có 3 chức năng chính: **Quản lý Voucher**, **Quản lý Căn tin (Gian hàng)**, và **Quản lý Tài khoản**. Dưới đây là kế hoạch chi tiết để xây dựng phân hệ Admin.

## 1. Kiến trúc Giao diện (Admin UI Layout)
Admin thường cần thao tác với bảng biểu và nhiều dữ liệu, do đó giao diện nên được thiết kế theo dạng **Dashboard (Bảng điều khiển)**.
- **Nền tảng:** Bạn có thể tích hợp thẳng vào App Flutter hiện tại (hiển thị menu Admin riêng nếu `role == 3`), hoặc tách ra một trang Web Admin riêng (nếu dùng Flutter Web hoặc React). Việc tích hợp thẳng vào App hiện tại sẽ nhanh hơn.
- **Bố cục (Layout):**
  - **Sidebar / Bottom Navigation:** Chứa các tab chính:
    - 📊 Dashboard (Thống kê tổng quan)
    - 🏪 Quản lý Căn tin
    - 👥 Quản lý Tài khoản
    - 🎟️ Quản lý Voucher

---

## 2. Chi tiết các Chức năng (Dựa trên Use Case)

### 2.1. Quản lý Căn tin (Gian hàng)
Admin là người nắm quyền cao nhất để cấp phép cho các gian hàng hoạt động trong trường học.
- **Hiển thị:** Danh sách các gian hàng (Tên, Hình ảnh, Trạng thái hoạt động, Tổng doanh thu).
- **Thêm mới:** Admin tạo gian hàng mới, đồng thời cấp tài khoản cấp "Nhân viên/Chủ quán" (`role = 2`) để họ đăng nhập và quản lý quán.
- **Chỉnh sửa/Xóa:** Cập nhật thông tin gian hàng hoặc **Khóa/Đóng cửa** gian hàng nếu vi phạm nội quy.

### 2.2. Quản lý Tài khoản
- **Hiển thị:** Danh sách toàn bộ người dùng trong hệ thống.
- **Phân loại:** Lọc theo Role (Khách hàng, Nhân viên gian hàng, Admin).
- **Thao tác:**
  - Chỉnh sửa thông tin cơ bản.
  - Phân quyền (Nâng cấp một sinh viên thành nhân viên gian hàng).
  - **Khóa tài khoản (Ban/Unban):** Cực kỳ quan trọng để xử lý các tài khoản thường xuyên "bom hàng" hoặc có hành vi gian lận.

### 2.3. Quản lý Voucher (Khuyến mãi)
Admin có thể tạo các chiến dịch khuyến mãi để kích cầu sinh viên mua sắm.
- **Thêm Voucher:** Tạo mã giảm giá với các thông số:
  - Mã voucher (Ví dụ: `WELCOME20`).
  - Loại giảm giá (Giảm theo % hoặc giảm thẳng số tiền).
  - Điều kiện áp dụng (Đơn tối thiểu bao nhiêu).
  - Thời hạn (Ngày bắt đầu - kết thúc) & Số lượng giới hạn.
- **Quản lý:** Tạm ngưng, xóa, hoặc xem thống kê số lượt đã sử dụng của từng mã Voucher.

---

## 3. Các bước Thực thi (Task Breakdown)

### Bước 1: Chuẩn bị Database (Backend)
- Thêm cột `trangThai` (active/banned) vào bảng `taikhoan` (nếu chưa có) để phục vụ tính năng Khóa tài khoản.
- Thêm cột `trangThai` vào bảng `gianhang` để phục vụ tính năng Đóng cửa gian hàng.
- Kiểm tra lại bảng `promotions` (Voucher) để đảm bảo hỗ trợ phân loại voucher của Admin (áp dụng toàn sàn) và voucher của từng Gian hàng riêng.

### Bước 2: Xây dựng Admin APIs (Backend)
Tạo một thư mục/router riêng cho admin (ví dụ: `adminRoutes.js`) với middleware `authorizeRole([3])` để bảo mật:
- `GET/POST/PUT /api/admin/stores` (Quản lý căn tin)
- `GET/PUT /api/admin/users` (Quản lý tài khoản & phân quyền)
- `GET/POST/PUT /api/admin/vouchers` (Quản lý voucher)

### Bước 3: Dựng Giao diện Admin (Frontend)
- Tạo thư mục `view/admin/` trong Flutter.
- Dựng các màn hình:
  - `admin_dashboard_view.dart`
  - `manage_stores_view.dart`
  - `manage_users_view.dart`
  - `manage_vouchers_view.dart`
- Thêm logic kiểm tra lúc Đăng nhập: Nếu API trả về `role == 3`, điều hướng thẳng vào `AdminDashboardView` thay vì `CustomerHomeView`.

---

> [!IMPORTANT]
> **User Review Required: Lựa chọn nền tảng cho Admin**
> 1. Bạn muốn giao diện Admin nằm chung trong cái **App Mobile** hiện tại (thuận tiện code chung 1 project), HAY bạn muốn tách thành **Website Dashboard** (thường Admin dùng trên máy tính sẽ dễ quản lý bảng biểu hơn)?
> 2. Về quản lý Voucher, bạn muốn Admin tạo voucher áp dụng chung cho TẤT CẢ gian hàng, hay Admin có thể tạo voucher áp dụng riêng cho từng gian hàng cụ thể?

> [!TIP]
> Việc xây dựng phân hệ Admin nên bắt đầu từ API Backend trước (Quản lý Tài khoản & Gian hàng). Khi API đã vững, việc ráp UI lên App hoặc Web sẽ cực kỳ nhanh chóng.
