# Tối ưu Quy trình Giao hàng: Giao hàng theo Món (Item-Level Delivery)

Dựa trên yêu cầu mới của bạn: **Giao hàng ngay khi xong từng món, không cần đợi xong toàn bộ đơn (kể cả trong cùng 1 món nhưng số lượng nhiều như 2 cơm gà, xong 1 phần thì đi giao luôn 1 phần)**. 

Đây là mô hình **Giao hàng phân mảnh (Partial Delivery)**, tập trung vào việc quản lý trạng thái của **từng phần ăn** thay vì cả một đơn hàng.

---

## Ý Tưởng & Luồng Hoạt Động Mới

### 1. Kéo KDS (Prepare) -> Lưu tạm vào "Trạm chờ giao"
- Tại màn hình KDS (Prepare), khi bếp làm xong **1 phần ăn** và kéo hoàn thành (Swipe), hệ thống không cập nhật trạng thái của cả `donhang`.
- Thay vào đó, hệ thống chỉ cập nhật `chitietdonhang` đó thành trạng thái `ready` (Sẵn sàng giao).
- Món ăn vừa kéo sẽ lập tức "bay" sang một giao diện mới: **Tab Giao Hàng**.

### 2. Giao diện Giao Hàng (Delivery Pool)
- Đây là nơi chứa **tất cả các phần ăn đã nấu xong nhưng chưa đi giao** của gian hàng.
- Giao diện này sẽ nhóm các món ăn đã xong theo Tòa nhà / Phòng để nhân viên dễ nhìn.
- **Thao tác:** Nhân viên nhìn vào danh sách này, xách các bịch đồ ăn tương ứng lên tay, sau đó bấm nút **"Giao hàng" (Start Delivery)**.

### 3. Tự động gom chuyến giao hàng (Dynamic Delivery Trip)
- Khi nhân viên bấm "Giao hàng", hệ thống sẽ **tự động gom tất cả các món đang ở trạng thái `ready`** trên màn hình lúc đó thành một "Chuyến giao hàng" (Delivery Trip).
- Trạng thái của các món này chuyển từ `ready` sang `delivering` (Đang giao).
- Nhân viên cầm đồ ăn đi phát cho từng phòng. Sau khi phát xong, bấm "Hoàn thành chuyến", các món đó chuyển thành `delivered`.

---

## Các Bước Triển Khai (Implementation Plan)

### Bước 1: Cấu trúc lại Database (Chuyển trọng tâm sang `chitietdonhang`)
- Trạng thái giao hàng sẽ được quản lý chính ở bảng `chitietdonhang`. Cần bổ sung/sử dụng cột `trangThaiMon`:
  - `pending`: Bếp đang nấu.
  - `ready`: Đã nấu xong, đang nằm ở Tab Giao Hàng chờ người mang đi.
  - `delivering`: Nhân viên đang trên đường đi giao.
  - `delivered`: Đã giao cho khách.
- **Tách dòng số lượng lúc đặt hàng:** Nếu khách mua "Cơm Gà" số lượng 2, lúc tạo đơn (Checkout) backend sẽ tự động insert thành 2 dòng `chitietdonhang` riêng biệt (mỗi dòng `soLuong = 1` và có ID riêng). Điều này để quản lý trạng thái độc lập của từng phần.
- **Tái sử dụng bảng `nhomgiaohang`**: Bảng này trước đây dùng để gom tự động bằng CronJob. Giờ đây, nó sẽ đại diện cho **1 Chuyến đi giao của Nhân viên**. Bảng `chitietdonhang` cần thêm cột `maNhomGiaoHang` để biết món này đang đi ở chuyến nào.

### Bước 2: Cập nhật Màn hình KDS (Prepare) - Giao diện Lớp Cha / Lớp Con
- Để tối ưu UX/UI cho đầu bếp (tránh bị rối mắt khi rã dòng ở DB), KDS sẽ hiển thị theo dạng **gộp nhóm (Lớp Cha - Lớp Con)**:
  - **Lớp Cha:** Gộp các món giống nhau trong cùng một đơn hàng thành 1 Thẻ (Card). Hiển thị tổng số lượng và tiến độ (VD: `Cơm Gà x 2` | `Tiến độ: 0/2`).
  - **Lớp Con (Xổ xuống):** Khi bấm vào Lớp Cha, sẽ xổ xuống các dòng chi tiết (tương ứng với các dòng `chitietdonhang` `soLuong=1` dưới DB).
- **Thao tác:** Bếp nấu xong phần nào thì quẹt/hoàn thành phần con đó. 
  - Gọi API `markItemReady(maChiTietDonHang)` để cập nhật phần con thành `ready` và đẩy sang Tab Giao Hàng.
  - Tiến độ Lớp Cha tự động cập nhật (VD: `1/2`). Khi xong hết các lớp con, Lớp Cha biến mất khỏi màn hình chờ nấu.

### Bước 3: Cập nhật Giao diện (Frontend - App Nhân viên)
Để tạo không gian cho tính năng Giao hàng mà không làm rối màn hình, ta sẽ cấu trúc lại thanh điều hướng dưới cùng (Bottom Navigation) và các menu:

1. **Đồng bộ UI Bottom Navigation với App Khách hàng:**
   - **Nút trung tâm (Menu):** Tab "Menu" (Quản lý thực đơn) sẽ được thiết kế thành một nút tròn nổi bật ở giữa thanh điều hướng (tương tự như nút Home màu cam của app khách hàng).
   - **Đổi Tab "More" thành Tab "Ship" (Giao hàng):** Tab ngoài cùng bên phải ở dưới cùng (hiện đang là "More" với icon `...`) sẽ được đổi tên thành **"Ship"** (hoặc "Delivery") với icon chiếc xe giao hàng.
   - Khi bấm vào Tab "Ship", màn hình Giao diện Giao Hàng (Delivery Pool) sẽ hiện ra. Tại đây nhân viên thấy các món đã `ready` và có nút "Bắt đầu đi giao".

2. **Di chuyển các chức năng của Tab More cũ:**
   - Tại màn hình của **Tab "Menu" (Quản lý thực đơn)**, thêm một biểu tượng dấu 3 chấm `...` (More) ở góc trên cùng bên phải (App Bar).
   - Khi bấm vào icon `...` này, một menu xổ xuống sẽ hiển thị các chức năng tiện ích trước đây của tab More, bao gồm:
     - **Store Information** (Thông tin gian hàng)
     - **Quản lý Voucher**
     - Các cài đặt khác (nếu có như Profile, Ngôn ngữ, Đăng xuất).

### Bước 4: Chức năng Gom Chuyến tại Tab "Ship" (Backend + Frontend)
- **Backend:** 
  - API `getReadyItems(maGianHang)`: Lấy các món đang `ready`.
  - API `startDeliveryTrip(danhSachMaChiTiet)`: Tạo chuyến, đổi các món thành `delivering`.
  - API `completeTrip(maNhomGiaoHang)`: Hoàn tất chuyến, đổi thành `delivered`.
- **Frontend (Tab "Ship"):** 
  - Hiển thị danh sách món `ready` chờ giao.
  - Có nút bấm "Bắt đầu giao chuyến này".

### Bước 5: Đồng bộ trạng thái Đơn hàng gốc (`donhang`)
Trạng thái của `donhang` sẽ là **trạng thái phái sinh** từ các món bên trong nó:
- Nếu toàn bộ món là `pending` -> `donhang` là `dangChuanBi`.
- Nếu có ít nhất 1 món `delivering` hoặc `delivered` -> `donhang` là `dangGiao` (Báo cho khách biết đang có món tới).
- Khi toàn bộ món đều là `delivered` -> `donhang` tự động thành `daGiao`.

---


> [!TIP]
> Mô hình "Delivery Trip" này rất thực tế giống cách chạy bàn của nhà hàng: Bếp ra món nào để lên quầy Pass (Tab Giao Hàng), bồi bàn (Nhân viên) rảnh tay sẽ gom hết các món trên quầy bỏ vào khay mang đi 1 vòng. Khách hàng sẽ được ăn đồ nóng nhất có thể.
