# Danh Sách Test Cases Hệ Thống - Phân Hệ Admin & Nhân Viên (Staff/Store Owner)

Tài liệu này tổng hợp toàn bộ các test cases cho phân hệ quản trị bao gồm:
1. **Admin (Role 3)**: Quản trị viên toàn hệ thống.
2. **Nhân viên / Chủ quán (Role 2)**: Quản lý gian hàng, thực đơn, khuyến mãi riêng và chuẩn bị món ăn tại bếp (KDS).

Các test cases được xây dựng đồng bộ theo đúng cấu trúc thực tế của mã nguồn backend (controllers, routes) và frontend của dự án.

---

## PHẦN A. TEST CASES DÀNH CHO ADMIN (TC01 - TC27)

### 1. Nhóm Chức Năng Đăng Nhập & Dashboard (TC01 - TC06)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC01** | Đăng nhập admin | Tài khoản admin đã tồn tại | Admin đăng nhập vào hệ thống | `admin@iuh.edu.vn` / `123456` | Đăng nhập thành công, vào dashboard admin | Đăng nhập thành công | Pass |
| **TC02** | Đăng nhập sinh viên | Tài khoản sinh viên đã tồn tại | Sinh viên đăng nhập vào hệ thống | `hoailoc0505@gmail.com` / `123456` | Đăng nhập thành công, vào giao diện hồ sơ | Đăng nhập thành công | Pass |
| **TC03** | Xem số liệu thống kê tổng quan | Admin đã đăng nhập thành công | Admin xem các chỉ số tổng hợp trên Dashboard | Không yêu cầu | Hệ thống hiển thị chính xác số lượng: Tổng tài khoản, Tổng khách hàng, Tổng nhân viên, Tổng gian hàng, Tổng đơn hàng, Tổng doanh thu, Tổng voucher đang hoạt động. | Hiển thị đúng và đầy đủ các chỉ số thống kê | Pass |
| **TC04** | Xem danh sách đơn hàng mới nhất | Admin đã đăng nhập thành công. Đã có đơn hàng trong hệ thống. | Admin xem danh sách 10 đơn hàng mới nhất hiển thị trên Dashboard | Không yêu cầu | Hiển thị đúng tối đa 10 đơn hàng gần nhất với các cột: Mã đơn hàng, Tên khách, Tòa nhà, Tổng tiền, Trạng thái, Thời gian đặt. Sắp xếp giảm dần theo thời gian. | Hiển thị đúng 10 đơn hàng gần nhất theo thứ tự thời gian | Pass |
| **TC05** | Xem thống kê doanh thu 6 tháng gần nhất | Admin đã đăng nhập thành công | Admin xem biểu đồ doanh thu hệ thống qua 6 tháng gần đây | Không yêu cầu | Biểu đồ doanh thu tải thành công, thể hiện chính xác doanh thu và số lượng đơn hàng của từng tháng tương ứng. | Biểu đồ hiển thị trực quan, đúng số liệu | Pass |
| **TC06** | Xem doanh thu theo từng gian hàng | Admin đã đăng nhập thành công | Admin xem danh sách doanh thu của từng gian hàng và lọc theo thời gian | Chọn bộ lọc: `Tháng này` | Danh sách hiển thị đúng tên gian hàng, banner, tổng đơn và tổng doanh thu tương ứng của tháng hiện tại, sắp xếp giảm dần theo doanh thu. | Lọc và hiển thị đúng doanh thu theo tháng của các gian hàng | Pass |

### 2. Nhóm Chức Năng Quản Lý Gian Hàng - Căn Tin (TC07 - TC13)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC07** | Xem danh sách gian hàng | Admin đã đăng nhập thành công | Admin xem danh sách toàn bộ các gian hàng trong hệ thống | Không yêu cầu | Hiển thị đầy đủ thông tin: Tên gian hàng, mô tả, hình ảnh banner, trạng thái hoạt động, tên chủ quán, email, tổng đơn và doanh thu. | Hiển thị đúng danh sách gian hàng hiện có trong database | Pass |
| **TC08** | Thêm mới gian hàng cùng tài khoản chủ quán | Admin đã đăng nhập thành công. Tên đăng nhập chủ quán chuẩn bị tạo chưa tồn tại. | Admin tạo mới một gian hàng và hệ thống tự động tạo tài khoản chủ quán (Role 2) liên kết với gian hàng đó. | Tên gian hàng: `Căn tin B1`<br>Mô tả: `Chuyên các món ăn trưa`<br>Tên đăng nhập: `cantinb1`<br>Mật khẩu: `123456`<br>Họ tên chủ quán: `Nguyễn Văn B`<br>Email: `cantinb1@iuh.edu.vn`<br>Số điện thoại: `0987654321` | Tạo gian hàng và tài khoản chủ quán thành công. Nhận thông báo "Tạo gian hàng thành công!", thông tin lưu đúng vào database. | Tạo thành công gian hàng và tài khoản chủ quán | Pass |
| **TC09** | Thêm mới gian hàng trùng tên đăng nhập chủ quán | Admin đã đăng nhập thành công. Tên đăng nhập chủ quán chuẩn bị tạo đã tồn tại trong DB. | Admin cố gắng tạo gian hàng mới với tên đăng nhập của chủ quán đã bị trùng. | Tên đăng nhập: `cantinb1` (đã tạo ở TC08) | Tạo thất bại, hệ thống hiển thị thông báo lỗi "Tên đăng nhập đã tồn tại." và không ghi nhận dữ liệu mới. | Hiển thị thông báo trùng tên đăng nhập chính xác | Pass |
| **TC10** | Cập nhật thông tin gian hàng | Gian hàng cần cập nhật thông tin đã tồn tại trong hệ thống | Admin cập nhật tên, mô tả và trạng thái hoạt động của gian hàng | Mã gian hàng: `1`<br>Tên gian hàng: `Căn tin B1 - Cập nhật`<br>Mô tả: `Phục vụ cả ngày`<br>Trạng thái: `Hoạt động (1)` | Cập nhật thành công thông tin gian hàng, nhận thông báo "Cập nhật gian hàng thành công!". Thông tin mới hiển thị ngay trên giao diện. | Thông tin gian hàng được cập nhật chính xác | Pass |
| **TC11** | Cập nhật ảnh banner gian hàng | Gian hàng cần cập nhật đã tồn tại. Ảnh tải lên đúng định dạng (png/jpg). | Admin tải ảnh banner mới lên cho gian hàng | Chọn file ảnh banner mong muốn | Tải lên thành công, nhận thông báo "Cập nhật ảnh gian hàng thành công!", hình ảnh banner mới được hiển thị trên giao diện của gian hàng. | Ảnh banner được cập nhật và hiển thị chính xác | Pass |
| **TC12** | Đóng cửa / Vô hiệu hóa gian hàng (Xóa mềm) | Gian hàng đang ở trạng thái Hoạt động | Admin chuyển trạng thái gian hàng sang ngừng hoạt động (trangThai = 0) | Chuyển Switch trạng thái của gian hàng sang `Tắt` | Trạng thái hoạt động chuyển sang "Ngừng hoạt động", nhận thông báo "Đã đóng cửa / xóa gian hàng thành công!". | Gian hàng đã chuyển sang ngừng hoạt động chính xác | Pass |
| **TC13** | Xem thống kê chi tiết của một gian hàng | Gian hàng được xem đã tồn tại và có doanh thu đơn hàng | Admin click xem chi tiết thống kê riêng của một gian hàng | Chọn gian hàng: `Căn tin B1` | Hệ thống hiển thị chi tiết: tổng đơn, tổng doanh thu, số món ăn, điểm đánh giá trung bình, số lượt đánh giá và biểu đồ doanh thu theo thời gian của gian hàng đó. | Các chỉ số chi tiết của gian hàng hiển thị đầy đủ và chính xác | Pass |

### 3. Nhóm Chức Năng Quản Lý Tài Khoản (TC14 - TC20)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC14** | Xem danh sách tài khoản người dùng | Admin đã đăng nhập thành công | Admin xem danh sách toàn bộ khách hàng và nhân viên căn tin (loại trừ tài khoản admin) | Không yêu cầu | Hiển thị đầy đủ thông tin: Mã tài khoản, Tên đăng nhập, Họ tên, Email, Số điện thoại, Vai trò và Trạng thái hoạt động của các tài khoản. | Hiển thị danh sách tài khoản chính xác | Pass |
| **TC15** | Tạo tài khoản khách hàng mới | Tên đăng nhập chuẩn bị tạo chưa tồn tại trên hệ thống | Admin tạo tài khoản mới với vai trò là Khách hàng (Role 1) | Tên đăng nhập: `student_test`<br>Mật khẩu: `123456`<br>Họ tên: `Nguyễn Văn Sinh Viên`<br>Email: `student_test@iuh.edu.vn`<br>Số điện thoại: `0912345678`<br>Vai trò: `Khách hàng (1)` | Tạo tài khoản thành công, nhận thông báo "Tạo tài khoản thành công!", tài khoản mới xuất hiện trong danh sách. | Tạo tài khoản khách hàng mới thành công | Pass |
| **TC16** | Khóa tài khoản người dùng có thời hạn | Tài khoản người dùng đang ở trạng thái Hoạt động | Admin thực hiện khóa tài khoản vi phạm trong một số ngày nhất định | Chọn tài khoản: `student_test`<br>Hành động: `ban_days`<br>Số ngày khóa: `7` ngày | Trạng thái tài khoản chuyển sang Bị khóa, trường thời gian khóa lưu mốc 7 ngày sau, nhận thông báo "Đã khóa tài khoản 7 ngày.". | Tài khoản đã bị khóa tạm thời 7 ngày chính xác | Pass |
| **TC17** | Khóa tài khoản người dùng vĩnh viễn | Tài khoản người dùng đang hoạt động | Admin khóa vĩnh viễn tài khoản người dùng vi phạm nghiêm trọng | Chọn tài khoản: `student_test`<br>Hành động: `ban_forever` | Trạng thái tài khoản chuyển sang Bị khóa, kích hoạt cờ khóa vĩnh viễn, nhận thông báo "Đã khóa tài khoản vĩnh viễn.". | Tài khoản đã bị khóa vĩnh viễn chính xác | Pass |
| **TC18** | Mở khóa tài khoản người dùng | Tài khoản người dùng đang ở trạng thái Bị khóa | Admin mở khóa cho tài khoản để họ tiếp tục sử dụng hệ thống | Chọn tài khoản: `student_test`<br>Hành động: `unban` | Trạng thái tài khoản chuyển sang Hoạt động (1), xóa bỏ các mốc thời gian khóa, nhận thông báo "Đã mở khóa tài khoản.". | Mở khóa tài khoản thành công | Pass |
| **TC19** | Cập nhật thông tin tài khoản | Tài khoản người dùng cần chỉnh sửa đã tồn tại | Admin cập nhật họ tên, email, số điện thoại hoặc vai trò của tài khoản | Mã tài khoản: `15`<br>Họ tên: `Nguyễn Văn A - Sửa`<br>Email: `nguyenvana_edit@gmail.com`<br>Số điện thoại: `0999888777`<br>Vai trò: `Nhân viên (2)` | Cập nhật thành công, nhận thông báo "Cập nhật tài khoản thành công!". Dữ liệu mới được cập nhật trong DB và hiển thị trên màn hình. | Thông tin tài khoản được cập nhật chính xác | Pass |
| **TC20** | Xóa mềm tài khoản người dùng | Tài khoản cần xóa không phải là tài khoản Admin | Admin xóa mềm tài khoản bằng cách đưa trạng thái về 0 để vô hiệu hóa | Chọn tài khoản muốn xóa | Nhận thông báo "Đã xóa tài khoản (có thể khôi phục lại).", trạng thái tài khoản trên giao diện chuyển sang vô hiệu hóa. | Xóa mềm tài khoản thành công | Pass |

### 4. Nhóm Chức Năng Quản Lý Mã Giảm Giá - Voucher Toàn Sàn (TC21 - TC25)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC21** | Xem danh sách mã giảm giá (Voucher) | Admin đã đăng nhập thành công | Admin xem danh sách tất cả các voucher đang hoạt động hoặc đã tắt trên hệ thống | Không yêu cầu | Giao diện hiển thị danh sách voucher kèm các thông tin: Mã code, Tên chương trình, % giảm, Số lượt dùng tối đa, Thời gian áp dụng, Nguồn voucher (admin/store), Căn tin áp dụng và Số lượt đã lưu. | Hiển thị đầy đủ thông tin danh sách voucher | Pass |
| **TC22** | Tạo mới Voucher áp dụng toàn sàn (Admin Voucher) | Mã voucher chuẩn bị tạo chưa tồn tại trên hệ thống | Admin tạo một voucher mới có hiệu lực cho tất cả các gian hàng trên hệ thống | Mã code: `IUHFOOD50`<br>Tên chương trình: `Khuyến mãi chào hè`<br>Mô tả: `Giảm 50% cho tất cả đơn hàng`<br>Phần trăm giảm: `50`<br>Số lần sử dụng tối đa: `100`<br>Thời gian bắt đầu: `2026-06-01 00:00:00`<br>Thời gian kết thúc: `2026-06-30 23:59:59`<br>Áp dụng: `Toàn sàn` | Tạo thành công, nhận thông báo "Tạo voucher thành công!", voucher hiển thị trong danh sách với nguồn voucher là `admin` và gian hàng áp dụng là `Toàn sàn`. | Tạo thành công voucher toàn sàn | Pass |
| **TC23** | Tạo mới Voucher áp dụng cho nhiều gian hàng cụ thể | Mã voucher chưa tồn tại. Các gian hàng được chọn đang hoạt động. | Admin tạo một voucher và chỉ áp dụng cho một số gian hàng cụ thể trong danh sách. | Mã code: `CANTEEN10`<br>Tên chương trình: `Giảm giá ngày hội`<br>Phần trăm giảm: `10`<br>Danh sách gian hàng: `[1, 2]` (Căn tin B1, Căn tin A2) | Hệ thống tạo ra các bản ghi voucher tương ứng cho từng gian hàng được chọn với cùng mã giảm giá. Nhận thông báo "Tạo voucher thành công!". | Voucher được tạo thành công cho các gian hàng đã chọn | Pass |
| **TC24** | Cập nhật thông tin Voucher | Voucher cần cập nhật thông tin đã tồn tại trong hệ thống | Admin chỉnh sửa thông tin mô tả, phần trăm giảm giá, số lượt dùng tối đa, thời gian áp dụng hoặc trạng thái của voucher | Mã voucher: `10`<br>Tên chương trình: `Khuyến mãi chào hè - Cập nhật`<br>Phần trăm giảm: `40`<br>Trạng thái hoạt động: Switch sang `Tắt` | Cập nhật thành công thông tin voucher, nhận thông báo "Cập nhật voucher thành công!". Voucher không còn hoạt động trên hệ thống. | Thông tin voucher được chỉnh sửa chính xác | Pass |
| **TC25** | Xóa vĩnh viễn Voucher | Voucher cần xóa đã tồn tại | Admin xóa hoàn toàn voucher khỏi hệ thống và xóa khỏi danh sách đã lưu của khách hàng | Chọn voucher và nhấn `Xóa` (biểu tượng thùng rác) | Hệ thống thực hiện xóa bản ghi trong bảng giamgia và giamgia_daluu, nhận thông báo "Đã xóa vĩnh viễn voucher khỏi hệ thống.". Voucher không còn xuất hiện trong danh sách. | Xóa vĩnh viễn voucher thành công | Pass |

### 5. Nhóm Chức Năng Quản Lý Đơn Hàng (TC26 - TC27)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC26** | Xem danh sách đơn hàng trên hệ thống | Admin đã đăng nhập thành công. Đã có đơn hàng trong hệ thống. | Admin xem danh sách toàn bộ các đơn hàng của tất cả người dùng đặt từ các gian hàng | Không yêu cầu | Giao diện hiển thị danh sách đơn hàng bao gồm: Mã đơn hàng, Tên khách hàng, Số điện thoại, Tổng tiền, Trạng thái đơn hàng, Thời gian đặt, Tên tòa nhà, Tên phòng và Danh sách các món ăn trong đơn hàng đó. | Danh sách đơn hàng hiển thị đầy đủ thông tin chi tiết | Pass |
| **TC27** | Lọc danh sách đơn hàng theo trạng thái | Hệ thống có đơn hàng ở các trạng thái khác nhau | Admin lọc danh sách đơn hàng để chỉ xem các đơn hàng ở một trạng thái nhất định | Chọn bộ lọc trạng thái đơn hàng: `Đã giao` (daGiao) | Hệ thống lọc và hiển thị danh sách chỉ gồm các đơn hàng có trạng thái là "Đã giao". | Danh sách hiển thị chính xác các đơn hàng có trạng thái "Đã giao" | Pass |

---

## PHẦN B. TEST CASES DÀNH CHO NHÂN VIÊN / CHỦ QUÁN (TC28 - TC42)

### 6. Nhóm Quản Lý Thông Tin Gian Hàng (TC28 - TC30)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC28** | Xem thông tin gian hàng của tôi | Nhân viên/chủ quán đã đăng nhập thành công | Chủ quán xem thông tin chi tiết về gian hàng của mình | Không yêu cầu | Giao diện hiển thị đúng thông tin gian hàng liên kết với tài khoản: Tên gian hàng, mô tả, ảnh banner và trạng thái. | Hiển thị đúng thông tin gian hàng của tôi | Pass |
| **TC29** | Cập nhật thông tin gian hàng | Nhân viên/chủ quán đã đăng nhập thành công | Chủ quán thay đổi tên và mô tả của gian hàng | Tên gian hàng: `Căn tin B1 - Premium`<br>Mô tả: `Chuyên các món ăn trưa chất lượng cao, phục vụ nhanh.` | Cập nhật thành công, nhận thông báo lưu thành công, thông tin mới cập nhật ngay trên giao diện của chủ quán và khách hàng. | Cập nhật thông tin gian hàng thành công | Pass |
| **TC30** | Tải lên banner mới cho gian hàng | Nhân viên/chủ quán đã đăng nhập thành công. Định dạng file ảnh hợp lệ. | Chủ quán tải ảnh banner mới đại diện cho gian hàng | Chọn file ảnh banner mong muốn | Ảnh banner được tải lên thành công, hệ thống cắt ảnh và lưu đúng đường dẫn, hiển thị banner mới trên trang gian hàng. | Banner được cập nhật và hiển thị chính xác | Pass |

### 7. Nhóm Quản Lý Thực Đơn & Món Ăn (TC31 - TC36)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC31** | Xem thực đơn đang bán | Nhân viên/chủ quán đã đăng nhập thành công | Chủ quán xem các món ăn đang được mở bán tại gian hàng của mình | Không yêu cầu | Giao diện hiển thị chính xác danh sách các món ăn chưa bị xóa với đầy đủ hình ảnh, tên món, giá, mô tả và trạng thái. | Hiển thị đúng thực đơn đang bán | Pass |
| **TC32** | Xem danh sách món ăn đã ngừng bán (Tab Ngừng bán) | Nhân viên/chủ quán đã đăng nhập thành công | Chủ quán xem danh sách các món ăn đã được ẩn hoặc ngừng kinh doanh trước đó | Không yêu cầu | Hiển thị đúng danh sách các món ăn đã bị xóa mềm (`daXoa = 1`) để theo dõi hoặc phục vụ mục đích khôi phục. | Hiển thị đúng danh sách món ăn đã ẩn | Pass |
| **TC33** | Thêm món ăn mới vào thực đơn | Chủ quán điền đầy đủ các thông tin bắt buộc của món ăn. Ảnh đúng định dạng. | Chủ quán tạo thêm món ăn mới vào thực đơn kinh doanh | Tên món: `Cơm sườn nướng`<br>Mô tả: `Sườn nướng mật ong thơm ngon`<br>Giá bán: `35000`<br>Hình ảnh: Chọn ảnh `com_suon.jpg` | Món ăn mới được thêm thành công, nhận thông báo "Thêm món ăn thành công!", món ăn hiển thị trong tab "Đang bán". | Thêm món ăn mới thành công | Pass |
| **TC34** | Cập nhật thông tin món ăn | Món ăn cần chỉnh sửa đã có trong thực đơn của quán | Chủ quán sửa thông tin tên, mô tả hoặc giá bán của một món ăn | Mã món ăn: `5`<br>Tên món ăn: `Cơm sườn nướng đặc biệt`<br>Giá bán: `40000` | Thông tin được cập nhật thành công, nhận thông báo cập nhật thành công, giá bán của món ăn thay đổi chính xác trên menu. | Thông tin món ăn được cập nhật chính xác | Pass |
| **TC35** | Tạm ngưng bán / Xóa mềm món ăn | Món ăn đang ở trạng thái hoạt động | Chủ quán ngừng bán món ăn để ẩn khỏi thực đơn của khách hàng | Nhấn nút `Ngừng bán` hoặc `Xóa` trên dòng món ăn | Món ăn được chuyển trạng thái ngừng bán, ẩn khỏi menu khách hàng và tự động chuyển vào tab "Ngừng bán" của chủ quán. | Ngừng bán món ăn thành công | Pass |
| **TC36** | Khôi phục món ăn đã ngừng bán | Món ăn đang nằm ở tab "Ngừng bán" | Chủ quán khôi phục lại món ăn đã ngừng bán trước đây để tiếp tục kinh doanh | Chọn món ăn trong tab "Ngừng bán" và nhấn `Khôi phục` | Món ăn được khôi phục trạng thái bán hàng, quay lại danh sách "Đang bán" để khách hàng có thể tiếp tục đặt. | Khôi phục món ăn thành công | Pass |

### 8. Nhóm Quản Lý Voucher Riêng Của Gian Hàng (TC37 - TC40)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC37** | Xem danh sách voucher của gian hàng | Nhân viên/chủ quán đã đăng nhập thành công | Xem danh sách các mã giảm giá riêng do gian hàng tự phát hành | Không yêu cầu | Hiển thị đầy đủ danh sách các voucher do quán tạo ra bao gồm: mã code, % giảm, số lượt dùng tối đa, ngày hết hạn và trạng thái. | Hiển thị đúng danh sách voucher của gian hàng | Pass |
| **TC38** | Tạo mã giảm giá mới của gian hàng | Mã voucher chuẩn bị tạo chưa trùng lặp trong hệ thống | Chủ quán tạo voucher mới áp dụng cho toàn bộ món ăn của quán hoặc riêng một món | Tiêu đề: `Khai trương giảm giá`<br>Mã voucher: `WELCOMEB1`<br>Phần trăm giảm: `15`<br>Số lần sử dụng tối đa: `50`<br>Ngày hết hạn: `2026-06-15 23:59:59` | Tạo thành công voucher riêng của quán, nhận thông báo "Tạo voucher thành công!". | Tạo thành công voucher cho gian hàng | Pass |
| **TC39** | Sửa mã giảm giá của gian hàng | Voucher cần sửa đã được tạo trước đó | Chủ quán chỉnh sửa thông tin số lượt dùng hoặc ngày hết hạn của voucher | Mã voucher: `WELCOMEB1`<br>Số lần sử dụng tối đa: `100` | Cập nhật thành công các thông tin điều chỉnh của voucher, hiển thị đúng trên trang quản lý. | Cập nhật voucher thành công | Pass |
| **TC40** | Xóa mã giảm giá của gian hàng | Voucher cần xóa đã tồn tại trong danh sách của quán | Chủ quán xóa voucher để dừng chương trình khuyến mãi | Chọn voucher và nhấn `Xóa` | Bản ghi voucher được xóa hoàn toàn khỏi hệ thống, nhận thông báo "Đã xoá voucher.". | Xóa voucher của quán thành công | Pass |

### 9. Nhóm Chuẩn Bị Đơn Hàng Tại Bếp - KDS (TC41 - TC42)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC41** | Xem danh sách món ăn cần chuẩn bị trong bếp | Có khách hàng đặt món của quán và đơn hàng đã được xác nhận | Nhân viên bếp xem danh sách món ăn đang chờ chế biến | Không yêu cầu | Giao diện KDS hiển thị danh sách các món ăn ở trạng thái chờ chuẩn bị (đang nấu) kèm: Tên món, số lượng, ghi chú, mã đơn và thời gian đặt. | Danh sách món ăn chờ chuẩn bị hiển thị đầy đủ và chính xác | Pass |
| **TC42** | Đánh dấu hoàn thành chuẩn bị món ăn | Món ăn đang hiển thị trong danh sách chờ chuẩn bị ở màn hình KDS | Nhân viên bếp nhấn hoàn thành chế biến một món ăn | Nhấn nút `Hoàn thành` bên cạnh món ăn | Trạng thái của món ăn đó chuyển sang `ready` (chờ giao hàng), món ăn biến mất khỏi danh sách chờ chuẩn bị. Đồng bộ trạng thái đơn hàng chung. | Đánh dấu món ăn hoàn thành thành công | Pass |

---

### 10. Nhóm Nhận Đơn & Chuẩn Bị (Luồng Delivery) (TC43 - TC45)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC43** | Xem danh sách đơn hàng cần chuẩn bị (delivery) | Nhân viên đã đăng nhập. Đã có đơn hàng giao đến gian hàng. | Nhân viên xem toàn bộ đơn hàng delivery đang chờ xử lý của gian hàng mình | Không yêu cầu | Giao diện hiển thị danh sách các đơn hàng giao thuộc gian hàng, kèm thông tin: Mã đơn, Tên khách, Tòa nhà, Phòng, Trạng thái, Danh sách món. | Danh sách đơn hàng cần chuẩn bị hiển thị đúng và đầy đủ | Pass |
| **TC44** | Nhân viên bắt đầu chuẩn bị đơn hàng delivery | Đơn hàng đang ở trạng thái `choXacNhan` | Nhân viên nhấn "Bắt đầu làm" để chuyển đơn hàng sang trạng thái đang chuẩn bị | Chọn đơn hàng ở trạng thái `Chờ xác nhận` và nhấn `Bắt đầu` | Trạng thái đơn hàng chuyển sang `dangChuanBi`, nhận thông báo "Đã chuyển đơn sang trạng thái Đang chuẩn bị.". | Đơn hàng chuyển sang trạng thái đang chuẩn bị thành công | Pass |
| **TC45** | Đánh dấu toàn bộ đơn hàng đã sẵn sàng giao | Đơn hàng đang ở trạng thái `dangChuanBi`, tất cả món đã nấu xong | Nhân viên đánh dấu đơn hàng đã chuẩn bị xong, sẵn sàng giao đến khách | Chọn đơn hàng và nhấn `Hoàn thành chuẩn bị` | Trạng thái đơn hàng chuyển sang `choGiaoHang`, nhận thông báo "Đã đánh dấu đơn hoàn thành!". Nếu toàn bộ đơn trong nhóm đã xong, nhóm chuyển sang `dangGiao`. | Đơn hàng chuyển sang trạng thái sẵn sàng giao thành công | Pass |

---

### 11. Nhóm Quản Lý Gọi Món Tại Bàn - Dine-In (TC46 - TC53)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC46** | Xem thông tin QR Code của gian hàng | Nhân viên đã đăng nhập thành công | Nhân viên xem QR code để khách hàng quét vào gọi món tại bàn | Không yêu cầu | Giao diện hiển thị đúng thông tin: Deep link `shipfood://canteen/{id}`, Web link trỏ đến menu của quán, Tên gian hàng và Số bàn hiện tại. | QR thông tin hiển thị chính xác | Pass |
| **TC47** | Cập nhật số lượng bàn ăn của gian hàng | Nhân viên đã đăng nhập thành công | Nhân viên thiết lập số bàn ăn tối đa của quán để hệ thống quản lý dine-in | Số bàn: `20` | Cập nhật thành công, nhận thông báo "Đã cập nhật số lượng bàn ăn.", số bàn mới hiển thị chính xác trong thông tin QR. | Số bàn được cập nhật thành công | Pass |
| **TC48** | Cập nhật số lượng bàn với giá trị không hợp lệ | Nhân viên đã đăng nhập thành công | Nhân viên nhập số bàn là 0 hoặc giá trị âm | Số bàn: `0` | Hệ thống từ chối cập nhật, hiển thị thông báo lỗi "Số bàn không hợp lệ." | Kiểm tra validation số bàn chính xác | Pass |
| **TC49** | Xem danh sách đơn hàng gọi tại bàn | Nhân viên đã đăng nhập. Có khách hàng đã gọi món tại quán. | Nhân viên xem toàn bộ đơn hàng gọi tại bàn (dineIn) của quán | Không yêu cầu | Giao diện hiển thị danh sách đơn tại bàn bao gồm: Mã đơn, Tên khách, Số bàn, Danh sách món, Tổng tiền, Trạng thái đơn, Trạng thái thanh toán và Thời gian gọi. | Danh sách đơn tại bàn hiển thị đúng và đầy đủ | Pass |
| **TC50** | Bắt đầu chuẩn bị đơn tại bàn | Đơn tại bàn đang ở trạng thái `choXacNhan` | Nhân viên nhận và bắt đầu chuẩn bị đơn hàng gọi tại bàn | Chọn đơn và nhấn `Bắt đầu chuẩn bị` | Trạng thái đơn chuyển từ `choXacNhan` sang `dangChuanBi`, nhận thông báo "Đã bắt đầu chuẩn bị.". | Đơn tại bàn chuyển sang đang chuẩn bị thành công | Pass |
| **TC51** | Hoàn tất và bưng đơn ra cho khách tại bàn | Đơn tại bàn đang ở trạng thái `dangChuanBi` | Nhân viên đánh dấu đã bưng đầy đủ tất cả món ra cho khách | Chọn đơn và nhấn `Hoàn thành / Đã bưng ra` | Trạng thái đơn chuyển sang `daGiao`, tất cả chi tiết món trong đơn chuyển sang `delivered`, nhận thông báo "Đơn đã hoàn thành!". | Hoàn tất đơn tại bàn thành công | Pass |
| **TC52** | Thêm món vào đơn tại bàn đang phục vụ | Đơn tại bàn đang tồn tại. Món ăn được thêm thuộc gian hàng. | Nhân viên bổ sung thêm món theo yêu cầu phát sinh của khách tại bàn | Mã đơn: `101`<br>Thêm món: `Cơm tấm` (Mã: 5)<br>Số lượng: `2` | Món được thêm vào đơn (hoặc tăng số lượng nếu đã có), tổng tiền đơn tự động tính lại, nhận thông báo "Đã thêm món vào đơn.". | Thêm món vào đơn tại bàn thành công | Pass |
| **TC53** | Xóa món khỏi đơn tại bàn đang phục vụ | Đơn tại bàn đang tồn tại. Món cần xóa thuộc đơn và gian hàng. | Nhân viên xóa bỏ một món ăn khỏi đơn nếu khách đổi ý | Chọn đơn và nhấn `Xóa` bên cạnh món muốn hủy | Món ăn bị xóa khỏi chi tiết đơn hàng, tổng tiền đơn tự động tính lại, nhận thông báo "Đã xóa món.". | Xóa món khỏi đơn tại bàn thành công | Pass |

---

### 12. Nhóm Tab Giao Hàng - Delivery Trip (TC54 - TC57)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC54** | Xem danh sách món sẵn sàng chờ giao (Tab Ship) | Nhân viên đã đăng nhập. Có ít nhất một món đang ở trạng thái `ready`. | Nhân viên vào Tab Ship xem danh sách tất cả các món đã nấu xong và đang chờ được giao đến khách | Không yêu cầu | Giao diện Tab Ship hiển thị danh sách đầy đủ các món sẵn sàng giao, bao gồm: Tên món, Tên khách, Số phòng, Tên tòa nhà và Tổng tiền đơn tương ứng. | Danh sách món chờ giao hiển thị chính xác | Pass |
| **TC55** | Bắt đầu chuyến giao hàng cho một tòa nhà | Nhân viên đã đăng nhập. Có ít nhất một món ở trạng thái `ready` trong tòa nhà được chọn. | Nhân viên gom tất cả các món sẵn sàng trong cùng một tòa nhà thành một chuyến giao | Chọn Tòa nhà để giao: `Tòa A` (maToaNha: 1) và nhấn `Bắt đầu đi giao` | Hệ thống tạo chuyến giao mới, trạng thái tất cả các món trong chuyến chuyển sang `delivering`, trạng thái các đơn tương ứng chuyển sang `dangGiao`. Nhận thông báo "Đã bắt đầu chuyến giao N phần ăn!". | Chuyến giao hàng được tạo và bắt đầu thành công | Pass |
| **TC56** | Xem thông tin chuyến giao hàng đang diễn ra | Nhân viên đã đăng nhập. Đã có một chuyến giao đang thực hiện. | Nhân viên xem chi tiết các món đang được mang đi giao trong chuyến hiện tại | Không yêu cầu | Giao diện hiển thị đầy đủ danh sách các món trong chuyến đang giao: Tên món, Tên khách, Tòa nhà, Phòng, Trạng thái từng món. | Thông tin chuyến giao hiện tại hiển thị chính xác | Pass |
| **TC57** | Hoàn tất giao một món trong chuyến giao | Nhân viên đang trong chuyến giao. Có ít nhất một món ở trạng thái `delivering`. | Nhân viên xác nhận đã giao thành công một món ăn đến tay khách hàng | Nhấn `Đã giao` bên cạnh một món trong chuyến | Trạng thái món đó chuyển sang `delivered`. Nếu đây là món cuối cùng của đơn hàng, trạng thái đơn hàng tự động chuyển sang `daGiao`. Nhận thông báo "Hoàn tất giao món!". | Hoàn tất giao từng món thành công, đồng bộ trạng thái đơn hàng chính xác | Pass |

---

### 13. Nhóm Thống Kê Doanh Thu Gian Hàng (TC58)

| Test ID | Chức năng | Điều kiện trước | Mô tả | Dữ liệu Test | Kết quả mong muốn | Kết quả thực tế | Pass/Fail |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC58** | Xem thống kê doanh thu của gian hàng theo kỳ | Nhân viên/chủ quán đã đăng nhập thành công. Đã có đơn hàng hoàn thành trong kỳ cần xem. | Chủ quán xem báo cáo thống kê doanh thu của gian hàng mình theo ngày, tuần hoặc tháng | Chọn bộ lọc: `Tháng này` | Giao diện hiển thị số liệu thống kê bao gồm: Tổng doanh thu, Tổng số đơn hàng và Doanh thu theo từng mốc thời gian (ngày/tuần) trong kỳ được chọn. | Thống kê doanh thu gian hàng hiển thị đúng theo kỳ được lọc | Pass |

