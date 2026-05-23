-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th5 08, 2026 lúc 12:49 PM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `canteen`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `chitietdonhang`
--

CREATE TABLE `chitietdonhang` (
  `maChiTietDonHang` int(11) NOT NULL,
  `maDonHang` int(11) DEFAULT NULL,
  `maMonAn` int(11) DEFAULT NULL,
  `soLuong` int(11) NOT NULL,
  `giaTien` decimal(12,0) NOT NULL COMMENT 'Lưu giá tại thời điểm đặt',
  `trangThaiMon` varchar(20) DEFAULT 'pending',
  `maNhomGiaoHang` int(11) DEFAULT NULL,
  `ghiChu` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `chitietdonhang`
--

INSERT INTO `chitietdonhang` (`maChiTietDonHang`, `maDonHang`, `maMonAn`, `soLuong`, `giaTien`, `trangThaiMon`, `maNhomGiaoHang`, `ghiChu`) VALUES
(5001, 501, 1, 2, 38000, 'pending', NULL, 'Thêm cơm, lấy phần đùi, ít mỡ nhé quán ơi'),
(5002, 501, 16, 1, 10000, 'pending', NULL, 'Canh rong biển cho nhiều rong biển'),
(5003, 502, 3, 2, 25000, 'ready', NULL, 'Không hành lá'),
(5004, 503, 2, 1, 35000, 'pending', NULL, 'Mắm gừng nhiều cay'),
(5005, 503, 17, 1, 25000, 'pending', NULL, 'Gà mềm xíu');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `danhgia`
--

CREATE TABLE `danhgia` (
  `maDanhGia` int(11) NOT NULL,
  `maDonHang` int(11) DEFAULT NULL,
  `maMonAn` int(11) DEFAULT NULL,
  `soSao` int(11) DEFAULT NULL CHECK (`soSao` >= 1 and `soSao` <= 5),
  `binhLuan` text DEFAULT NULL,
  `hinhAnhDanhGia` text DEFAULT NULL COMMENT 'JSON array chứa URL ảnh đánh giá',
  `thoiGianDanhGia` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `danhgia`
--

INSERT INTO `danhgia` (`maDanhGia`, `maDonHang`, `maMonAn`, `soSao`, `binhLuan`, `hinhAnhDanhGia`, `thoiGianDanhGia`) VALUES
(501, 502, 3, 5, 'Cơm chiên siêu ngon, hạt cơm tơi xốp, ship siêu nhanh luôn ạ <3', '[]', '2026-05-08 07:34:22');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `danhmuc`
--

CREATE TABLE `danhmuc` (
  `maDanhMuc` int(11) NOT NULL,
  `tenDanhMuc` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `danhmuc`
--

INSERT INTO `danhmuc` (`maDanhMuc`, `tenDanhMuc`) VALUES
(1, 'Cơm'),
(2, 'Đồ uống'),
(3, 'Trà sữa'),
(4, 'Ăn vặt'),
(5, 'Tráng miệng'),
(6, 'Bún');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `donhang`
--

CREATE TABLE `donhang` (
  `maDonHang` int(11) NOT NULL,
  `maTaiKhoan` int(11) DEFAULT NULL,
  `maNhomGiaoHang` int(11) DEFAULT NULL,
  `tongTien` decimal(12,0) DEFAULT NULL,
  `trangThaiDonHang` varchar(50) DEFAULT NULL COMMENT 'choXacNhan, dangChuanBi, choGiaoHang, dangGiao, daGiao, daHuy',
  `thoiGianDat` datetime DEFAULT NULL,
  `maToaNha` int(11) NOT NULL,
  `maPhong` int(11) NOT NULL,
  `phuongThucThanhToan` varchar(20) DEFAULT 'COD',
  `trangThaiThanhToan` varchar(20) DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `donhang`
--

INSERT INTO `donhang` (`maDonHang`, `maTaiKhoan`, `maNhomGiaoHang`, `tongTien`, `trangThaiDonHang`, `thoiGianDat`, `maToaNha`, `maPhong`, `phuongThucThanhToan`, `trangThaiThanhToan`) VALUES
(501, 4, NULL, 86000, 'dangChuanBi', '2026-05-08 17:34:22', 1, 1, 'COD', 'pending'),
(502, 4, NULL, 50000, 'daGiao', '2026-05-07 17:34:22', 1, 2, 'VNPAY', 'paid'),
(503, 4, NULL, 60000, 'dangChuanBi', '2026-05-08 16:34:22', 2, 14, 'COD', 'pending');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `giamgia`
--

CREATE TABLE `giamgia` (
  `maGiamGia` int(11) NOT NULL,
  `maGianHang` int(11) DEFAULT NULL,
  `maMonAn` int(11) DEFAULT NULL COMMENT 'NULL = áp dụng toàn gian hàng',
  `maVoucher` varchar(40) DEFAULT NULL COMMENT 'Mã voucher (VD: SALE20)',
  `tenGiamGia` varchar(255) NOT NULL COMMENT 'Tên chương trình',
  `moTa` text DEFAULT NULL,
  `phanTramGiam` decimal(5,2) DEFAULT NULL COMMENT 'Phần trăm giảm (0-100)',
  `hinhAnhBanner` varchar(500) DEFAULT NULL,
  `thoiGianBatDau` datetime DEFAULT current_timestamp(),
  `thoiGianKetThuc` datetime NOT NULL COMMENT 'Bắt buộc có ngày hết hạn',
  `trangThai` tinyint(1) NOT NULL DEFAULT 1,
  `soLanToiDa` int(11) DEFAULT NULL COMMENT 'NULL = không giới hạn số lần sử dụng',
  `thoiGianTao` datetime NOT NULL DEFAULT current_timestamp(),
  `thoiGianCapNhat` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `nguonVoucher` enum('admin','store') NOT NULL DEFAULT 'store'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chương trình giảm giá / voucher do staff tạo';

--
-- Đang đổ dữ liệu cho bảng `giamgia`
--

INSERT INTO `giamgia` (`maGiamGia`, `maGianHang`, `maMonAn`, `maVoucher`, `tenGiamGia`, `moTa`, `phanTramGiam`, `hinhAnhBanner`, `thoiGianBatDau`, `thoiGianKetThuc`, `trangThai`, `soLanToiDa`, `thoiGianTao`, `thoiGianCapNhat`, `nguonVoucher`) VALUES
(1, 1, 1, 'COMGA20', 'Giảm 20% tất cả cơm gà', NULL, 20.00, NULL, '2026-05-02 11:41:22', '2026-05-03 00:00:00', 1, 1, '2026-05-02 11:41:22', '2026-05-02 18:52:41', 'store'),
(2, 2, NULL, 'BUNBO15', 'Giảm 15% bún bò & hủ tiếu', 'Áp dụng toàn bộ món tại Bún Bò & Hủ Tiếu Chú Năm', 15.00, NULL, '2026-05-02 11:41:22', '2026-05-05 11:41:22', 1, NULL, '2026-05-02 11:41:22', '2026-05-02 11:41:22', 'store'),
(3, 3, NULL, 'TRASUA10', 'Giảm 10% đồ uống', 'Toàn bộ trà sữa tại T-Station', 10.00, NULL, '2026-05-02 11:41:22', '2026-05-16 11:41:22', 1, NULL, '2026-05-02 11:41:22', '2026-05-02 11:41:22', 'store'),
(4, 4, NULL, 'COMTAM25', 'Giảm 25% cơm tấm cuối tuần', 'Thứ 7 & Chủ nhật tại Cơm Tấm Sinh Viên', 25.00, NULL, '2026-05-02 11:41:22', '2026-05-07 11:41:22', 1, NULL, '2026-05-02 11:41:22', '2026-05-02 11:41:22', 'store'),
(5, 5, 12, 'BANHMI30', 'Giảm 30% bánh mì heo quay', 'Chỉ áp dụng cho Bánh Mì Heo Quay', 30.00, NULL, '2026-05-02 11:41:22', '2026-05-04 11:41:22', 1, NULL, '2026-05-02 11:41:22', '2026-05-02 11:41:22', 'store'),
(6, 6, NULL, 'ANVAT10', 'Giảm 10% toàn bộ ăn vặt', 'Toàn bộ món tại Góc Ăn Vặt Tòa H', 10.00, NULL, '2026-05-02 11:41:22', '2026-05-12 11:41:22', 1, NULL, '2026-05-02 11:41:22', '2026-05-02 11:41:22', 'store'),
(7, 1, 1, '18FNV29G', 'CR7', NULL, 99.00, NULL, '2026-05-02 18:53:14', '2026-05-09 00:00:00', 1, 2, '2026-05-02 18:53:14', '2026-05-02 18:53:14', 'store'),
(8, 1, NULL, 'EMU18FNV', 'Mesi', NULL, 50.00, NULL, '2026-05-06 17:10:41', '2026-05-07 00:00:00', 1, 2, '2026-05-06 17:10:41', '2026-05-08 16:34:03', 'store');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `giamgia_daluu`
--

CREATE TABLE `giamgia_daluu` (
  `maGiamGiaDaLuu` int(11) NOT NULL,
  `maTaiKhoan` int(11) NOT NULL COMMENT 'FK → taikhoan.maTaiKhoan',
  `maGiamGia` int(11) NOT NULL COMMENT 'FK → giamgia.maGiamGia',
  `thoiGianLuu` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Voucher mà khách hàng đã thu thập';

--
-- Đang đổ dữ liệu cho bảng `giamgia_daluu`
--

INSERT INTO `giamgia_daluu` (`maGiamGiaDaLuu`, `maTaiKhoan`, `maGiamGia`, `thoiGianLuu`) VALUES
(1, 4, 1, '2026-05-02 05:16:58'),
(2, 4, 2, '2026-05-02 05:17:02'),
(3, 4, 7, '2026-05-02 11:53:44'),
(4, 108, 6, '2026-05-06 09:57:24'),
(5, 108, 4, '2026-05-06 09:57:26'),
(6, 108, 3, '2026-05-06 09:58:49'),
(7, 108, 7, '2026-05-06 09:57:36'),
(10, 108, 8, '2026-05-06 10:11:06'),
(11, 107, 4, '2026-05-06 13:52:49'),
(12, 107, 7, '2026-05-07 12:48:30'),
(13, 4, 3, '2026-05-08 06:27:38'),
(14, 4, 6, '2026-05-08 06:27:39');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `gianhang`
--

CREATE TABLE `gianhang` (
  `maGianHang` int(11) NOT NULL,
  `maTaiKhoan` int(11) DEFAULT NULL,
  `tenGianHang` varchar(100) NOT NULL,
  `moTa` text DEFAULT NULL,
  `banner` varchar(255) DEFAULT NULL,
  `soDienThoai` varchar(20) DEFAULT NULL,
  `gioMoCua` varchar(50) DEFAULT NULL,
  `trangThai` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `gianhang`
--

INSERT INTO `gianhang` (`maGianHang`, `maTaiKhoan`, `tenGianHang`, `moTa`, `banner`, `soDienThoai`, `gioMoCua`, `trangThai`) VALUES
(1, 101, 'Cơm Gà Xối Mỡ Cô Ba', 'Chuyên cơm gà xối mỡ đùi góc tư siêu to, da giòn rụm, kèm canh rong biển thanh mát. Có thêm cơm chiên dương châu.', 'http://10.0.2.2:3001/uploads/gianhang/comga.jpg', '0911111111', '07:00 - 15:30', 1),
(2, 102, 'Bún Bò & Hủ Tiếu Chú Năm', 'Đậm đà hương vị truyền thống. Nước dùng hầm từ xương bò 10 tiếng. Quán có bán kèm hủ tiếu gõ và mì xào giòn.', '/uploads/gianhang/chu5.jpg', '0922222222', '06:00 - 13:00', 1),
(3, 103, 'Trà Sữa T-Station', 'Trạm tiếp nhiên liệu cho những giờ học căng thẳng! Menu đa dạng từ trà sữa trân châu đường đen, trà đào cam sả đến các loại đá xay.', '/uploads/gianhang/ts.jpg', '0933333333', '07:30 - 17:00', 1),
(4, 104, 'Cơm Tấm Sinh Viên', 'Bao no, bao rẻ. Sườn nướng than hoa thơm lừng mắm tỏi. Có thêm chả cua, trứng ốp la đào và bì thính tự làm.', '/uploads/gianhang/ctsv.jpg', '0944444444', '09:00 - 14:00', 1),
(5, 105, 'Bánh Mì Kẹp & Fast Food', 'Giải pháp ăn sáng thần tốc cho sinh viên chạy deadline. Bánh mì heo quay, xíu mại trứng muối và hamburger bò băm.', '/uploads/gianhang/bm.jpg', '0955555555', '06:30 - 16:00', 1),
(6, 106, 'Góc Ăn Vặt Tòa H', 'Thiên đường ăn vặt với cá viên chiên mắm, bánh tráng trộn, trái cây tô và xúc xích nướng đá. Freeship tận phòng nếu đặt trên 5 món.', '/uploads/gianhang/anvat.jpg', '0966666666', '08:00 - 17:30', 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `giao_dich_vi`
--

CREATE TABLE `giao_dich_vi` (
  `id` int(11) NOT NULL,
  `maTaiKhoan` int(11) NOT NULL,
  `loai` enum('nap','rut','thanh_toan','hoan_tien') NOT NULL,
  `soTien` decimal(15,2) NOT NULL,
  `soDuTruoc` decimal(15,2) DEFAULT NULL,
  `soDuSau` decimal(15,2) DEFAULT NULL,
  `trangThai` enum('cho_xu_ly','hoan_thanh','that_bai') DEFAULT 'cho_xu_ly',
  `nganHang` varchar(50) DEFAULT NULL,
  `soTaiKhoanNH` varchar(50) DEFAULT NULL,
  `tenChuTK` varchar(100) DEFAULT NULL,
  `maGiaoDich` varchar(100) DEFAULT NULL,
  `ghiChu` text DEFAULT NULL,
  `thoiGian` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `giao_dich_vi`
--

INSERT INTO `giao_dich_vi` (`id`, `maTaiKhoan`, `loai`, `soTien`, `soDuTruoc`, `soDuSau`, `trangThai`, `nganHang`, `soTaiKhoanNH`, `tenChuTK`, `maGiaoDich`, `ghiChu`, `thoiGian`) VALUES
(1, 4, 'nap', 100000.00, NULL, NULL, 'cho_xu_ly', NULL, NULL, NULL, 'NAP41777724885318', 'Nạp tiền qua chuyển khoản ngân hàng', '2026-05-02 12:28:05'),
(2, 4, 'nap', 20000.00, NULL, NULL, 'cho_xu_ly', NULL, NULL, NULL, 'NAP41777725008589', 'Nạp tiền qua chuyển khoản ngân hàng', '2026-05-02 12:30:08');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `giohang`
--

CREATE TABLE `giohang` (
  `maTaiKhoan` int(11) NOT NULL,
  `maMonAn` int(11) NOT NULL,
  `soLuong` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng món ăn trong giỏ'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lưu trữ giỏ hàng của người dùng';

--
-- Đang đổ dữ liệu cho bảng `giohang`
--

INSERT INTO `giohang` (`maTaiKhoan`, `maMonAn`, `soLuong`) VALUES
(108, 3, 1),
(108, 12, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `monan`
--

CREATE TABLE `monan` (
  `maMonAn` int(11) NOT NULL,
  `maGianHang` int(11) DEFAULT NULL,
  `maDanhMuc` int(11) DEFAULT NULL,
  `tenMonAn` varchar(100) NOT NULL,
  `moTa` text DEFAULT NULL COMMENT 'Mô tả chi tiết món ăn',
  `giaTien` decimal(12,0) NOT NULL COMMENT 'Giá VND',
  `hinhAnh` varchar(255) DEFAULT NULL,
  `trangThai` tinyint(1) DEFAULT 1 COMMENT '1: Còn hàng, 0: Hết hàng',
  `daXoa` tinyint(1) DEFAULT 0 COMMENT '0: Bình thường, 1: Đã xóa mềm',
  `diemDanhGia` decimal(2,1) DEFAULT 0.0 COMMENT 'Điểm đánh giá trung bình (1.0 - 5.0)',
  `luotDanhGia` int(11) DEFAULT 0 COMMENT 'Tổng lượt đánh giá',
  `soLuongDaBan` int(11) DEFAULT 0 COMMENT 'Tổng số lượng đã bán',
  `soLuongTon` int(11) NOT NULL DEFAULT 99
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `monan`
--

INSERT INTO `monan` (`maMonAn`, `maGianHang`, `maDanhMuc`, `tenMonAn`, `moTa`, `giaTien`, `hinhAnh`, `trangThai`, `daXoa`, `diemDanhGia`, `luotDanhGia`, `soLuongDaBan`, `soLuongTon`) VALUES
(1, 1, 1, 'Cơm gà xối mỡ đùi góc tư', 'Đùi gà góc tư da giòn rụm, thịt mềm đậm vị. Xối mỡ hành phi thơm lừng, ăn kèm cơm trắng dẻo và nước kho gà.', 38000, 'http://10.0.2.2:3001/uploads/monan/duigagoc4.jpg', 1, 0, 4.3, 3, 3, 2),
(2, 1, 1, 'Cơm gà xối mỡ cánh', 'Cánh gà xối mỡ vàng ươm, da giòn tan. Ăn kèm dưa leo và nước mắm chua ngọt pha đúng vị.', 30000, '/uploads/monan/comgacanh.jpg', 0, 1, 0.0, 0, 0, 0),
(3, 1, 1, 'Cơm chiên Dương Châu', 'Cơm chiên thập cẩm với tôm, trứng, xúc xích và rau củ tươi. Xào lửa lớn phi thơm mỡ hành vàng óng.', 25000, '/uploads/monan/comchien.jpg', 1, 0, 4.0, 1, 4, 92),
(4, 2, 6, 'Bún bò Huế tô đặc biệt', 'Nước dùng hầm xương bò 10 tiếng, đậm đà hương sả và mắm ruốc đặc trưng. Tô đặc biệt có đủ bò, chả Huế, móng heo.', 40000, '/uploads/monan/bbhdb.jpg', 1, 0, 5.0, 2, 2, 94),
(5, 2, 6, 'Bún bò giò heo', 'Bún bò Huế chuẩn vị với giò heo mềm, thịt bò thái lát. Nước dùng cay nhẹ, thơm sả ớt.', 35000, '/uploads/monan/bbhgh.webp', 1, 0, 3.0, 1, 1, 97),
(6, 2, 6, 'Hủ tiếu gõ thịt băm', 'Hủ tiếu dai mềm chan nước dùng ngọt từ xương ống, ăn kèm thịt băm và hành phi giòn.', 20000, '/uploads/monan/htgtb.webp', 1, 0, 3.0, 1, 2, 97),
(7, 3, 3, 'Trà sữa trân châu đường đen', 'Trà sữa thơm mịn pha cùng đường đen đặc. Trân châu dai mềm ngâm nước đường đen sánh quyện.', 25000, '/uploads/monan/tsccd.webp', 1, 0, 4.7, 3, 3, 92),
(8, 3, 2, 'Trà đào cam sả', 'Vị chua ngọt nhẹ của đào pha cùng tinh dầu sả và nước cam tươi. Thanh mát, thích hợp cho ngày nóng.', 20000, '/uploads/monan/tdcs.jpg', 1, 0, 5.0, 3, 3, 95),
(9, 3, 3, 'Sữa tươi trân châu đường đen', 'Sữa tươi béo ngậy kết hợp trân châu đường đen dẻo mềm. Vị ngọt thanh, uống mát lạnh giải nhiệt.', 25000, '/uploads/monan/st.jpg', 1, 0, 4.0, 2, 2, 99),
(10, 4, 1, 'Cơm tấm sườn nướng', 'Sườn non nướng than hoa thơm lừng mắm tỏi, cơm tấm dẻo mịn. Ăn kèm chả trứng và bì thính tự làm.', 25000, '/uploads/monan/ctsn.jpg', 1, 0, 4.0, 1, 1, 97),
(11, 4, 1, 'Cơm tấm sườn bì chả', 'Combo đầy đủ cơm tấm, sườn nướng, bì thính và chả cua. Nước mắm chua ngọt pha đúng vị miền Nam.', 35000, '/uploads/monan/ctsbc.jpg', 1, 0, 5.0, 1, 1, 96),
(12, 5, 4, 'Bánh mì heo quay', 'Bánh mì giòn nhân heo quay da phồng, thơm phức. Kèm chả lụa, dưa chua và nước sốt đặc biệt.', 18000, '/uploads/monan/bmhq.webp', 1, 0, 4.0, 1, 1, 96),
(13, 5, 4, 'Bánh mì xíu mại trứng muối', 'Bánh mì nhân xíu mại thịt heo đậm đà ăn kèm trứng muối bùi béo. Sốt tương đỏ thơm ngon.', 20000, '/uploads/monan/xmtm.jpg', 1, 0, 4.0, 1, 1, 98),
(14, 6, 4, 'Cá viên chiên mắm (Phần nhỏ)', 'Cá viên chiên giòn rụm chấm nước mắm pha tỏi ớt cay ngọt. Ăn vặt lý tưởng giữa giờ học.', 20000, '/uploads/monan/cvcm.jpg', 1, 0, 5.0, 1, 1, 99),
(15, 6, 4, 'Bánh tráng trộn khô bò', 'Bánh tráng trộn đủ topping: khô bò, trứng cút, hành phi, sa tế. Vị cay mặn ngọt hòa quyện.', 15000, '/uploads/monan/bttkb.jpg', 1, 0, 4.0, 1, 2, 98),
(16, 1, 5, 'Canh rong biển thêm', 'Canh rong biển nấu xương gà thanh mát, bổ sung khoáng chất. Ăn kèm bữa cơm hàng ngày.', 10000, '/uploads/monan/crb.jpg', 1, 0, 3.5, 2, 2, 99),
(17, 1, 1, 'Cơm gà tam kỳ', NULL, 40000, '/uploads/monan/cgtk.jpeg', 1, 0, 0.0, 0, 0, 98);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `nhom`
--

CREATE TABLE `nhom` (
  `maNhom` varchar(36) NOT NULL DEFAULT uuid(),
  `tenNhom` varchar(255) NOT NULL,
  `anhDaiDien` varchar(512) DEFAULT NULL,
  `maMoi` varchar(20) NOT NULL,
  `maNguoiTao` int(11) NOT NULL,
  `trangThai` tinyint(1) NOT NULL DEFAULT 1,
  `thoiGianTao` datetime NOT NULL DEFAULT current_timestamp(),
  `thoiGianCapNhat` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `nhom`
--

INSERT INTO `nhom` (`maNhom`, `tenNhom`, `anhDaiDien`, `maMoi`, `maNguoiTao`, `trangThai`, `thoiGianTao`, `thoiGianCapNhat`) VALUES
('4d5a79eb-a5bb-4fe1-92d1-8d133f1d5852', 'Mesi', NULL, 'GR966D0', 108, 1, '2026-05-06 20:20:54', '2026-05-06 20:20:54'),
('fbd18cfd-8447-4464-981f-c4da072c0b8a', 'cr7', NULL, 'G1EDLVO', 108, 1, '2026-05-06 20:10:28', '2026-05-06 20:10:28');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `nhomgiaohang`
--

CREATE TABLE `nhomgiaohang` (
  `maNhomGiaoHang` int(11) NOT NULL,
  `thoiGianTaoNhom` datetime DEFAULT NULL,
  `trangThaiNhom` varchar(50) DEFAULT NULL COMMENT 'choGiaoHang, dangGiao, hoanThanh',
  `maToaNha` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `phong`
--

CREATE TABLE `phong` (
  `maPhong` int(11) NOT NULL,
  `tenPhong` varchar(50) NOT NULL,
  `maToaNha` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `phong`
--

INSERT INTO `phong` (`maPhong`, `tenPhong`, `maToaNha`) VALUES
(1, 'A1.01', 1),
(2, 'A1.02', 1),
(3, 'A1.03', 1),
(4, 'A1.04', 1),
(5, 'A2.01', 1),
(6, 'A2.02', 1),
(7, 'A2.03', 1),
(8, 'A2.04', 1),
(9, 'A3.01', 1),
(10, 'A3.02', 1),
(11, 'A3.03', 1),
(12, 'A3.04', 1),
(13, 'B1.01', 2),
(14, 'B1.02', 2),
(15, 'B1.03', 2),
(16, 'B2.01', 2),
(17, 'B2.02', 2),
(18, 'B2.03', 2),
(19, 'B3.01', 2),
(20, 'B3.02', 2),
(21, 'B3.03', 2),
(22, 'C1.01', 3),
(23, 'C1.02', 3),
(24, 'C2.01', 3),
(25, 'C2.02', 3),
(26, 'D1.01', 4),
(27, 'D1.02', 4),
(28, 'D2.01', 4),
(29, 'D2.02', 4);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `taikhoan`
--

CREATE TABLE `taikhoan` (
  `maTaiKhoan` int(11) NOT NULL,
  `maVaiTro` int(11) DEFAULT NULL,
  `tenDangNhap` varchar(50) NOT NULL,
  `matKhau` varchar(255) NOT NULL COMMENT 'Chuỗi Hash',
  `hoTen` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `soDienThoai` varchar(20) DEFAULT NULL,
  `anhDaiDien` varchar(255) DEFAULT NULL,
  `trangThai` tinyint(1) DEFAULT 1 COMMENT '1: Hoạt động, 0: Khóa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `taikhoan`
--

INSERT INTO `taikhoan` (`maTaiKhoan`, `maVaiTro`, `tenDangNhap`, `matKhau`, `hoTen`, `email`, `soDienThoai`, `anhDaiDien`, `trangThai`) VALUES
(2, 1, 'baostudent', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Nguyễn Văn Bảo', 'aaa@gmail.com', '0912345678', NULL, 1),
(4, 1, '123', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Duong Minh Quoc Bao', 'duongbao2304@gmail.com', '0353205835', '/uploads/anhdaidien/avatar-1776331958169-253758901.jpg', 1),
(101, 2, 'coba_comga', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Cô Ba Cơm Gà', NULL, '0911111111', NULL, 1),
(102, 2, 'chunam_bunbo', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Chú Năm Bún Bò', NULL, '0922222222', NULL, 1),
(103, 2, 'trasua_station', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Nguyễn Thị Nước', NULL, '0933333333', NULL, 1),
(104, 2, 'comtam_sv', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Trần Cơm Tấm', NULL, '0944444444', NULL, 1),
(105, 2, 'banhmi_hot', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Lê Bánh Mì', NULL, '0955555555', NULL, 1),
(106, 2, 'anvat_toah', '$2b$10$DBZrrKqHc9IPJ8LT2UboleeaNmUGl81kWBhq.sBuRoz...', 'Phạm Ăn Vặt', NULL, '0966666666', NULL, 1),
(107, 1, 'facebook_947275504840489', '', 'Ngọc Huy', 'dubao280@gmail.com', NULL, 'https://scontent.fsgn5-9.fna.fbcdn.net/v/t1.30497-1/84628273_176159830277856_972693363922829312_n.jpg?stp=dst-jpg_s200x200_tt6&_nc_cat=1&ccb=1-7&_nc_sid=7565cd&_nc_ohc=tBuVzoDYvk0Q7kNvwFz7H8l&_nc_oc=AdpjnkPMmT8ANZDsEYGd_WZefLxdGb1wMcaNLWx_O4e7-HilSI4ObZXj', 1),
(108, 1, 'google_102198748924958968710', '', 'Bảo Trần Dũ', 'dubao1005@gmail.com', NULL, 'https://lh3.googleusercontent.com/a/ACg8ocLHVjz4yvDa919gnUp5cAVNedymhRh5BwArV5FmnzpxCQLtpNK3', 1),
(109, 3, 'admin', '$2b$10$/HhEj0cf0ZfygX/3qnpPeOZR3XtwriJNT0Z1X0hzBh6oTEaEWuv7S', 'Quản trị viên', 'admin@fooddelivery.com', NULL, NULL, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `thanhtoan`
--

CREATE TABLE `thanhtoan` (
  `maTT` int(11) NOT NULL,
  `maDonHang` int(11) NOT NULL,
  `txnRef` varchar(50) NOT NULL,
  `soTien` decimal(15,0) NOT NULL,
  `trangThai` enum('pending','success','failed') DEFAULT 'pending',
  `maGiaoDich` varchar(50) DEFAULT NULL,
  `thoiGianTao` datetime DEFAULT current_timestamp(),
  `thoiGianHoanTat` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `thanhvien_nhom`
--

CREATE TABLE `thanhvien_nhom` (
  `maThanhVienNhom` int(11) NOT NULL,
  `maNhom` varchar(36) NOT NULL,
  `maTaiKhoan` int(11) NOT NULL,
  `vaiTro` enum('admin','member') NOT NULL DEFAULT 'member',
  `thoiGianThamGia` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `thanhvien_nhom`
--

INSERT INTO `thanhvien_nhom` (`maThanhVienNhom`, `maNhom`, `maTaiKhoan`, `vaiTro`, `thoiGianThamGia`) VALUES
(6, 'fbd18cfd-8447-4464-981f-c4da072c0b8a', 108, 'admin', '2026-05-06 20:10:28'),
(7, '4d5a79eb-a5bb-4fe1-92d1-8d133f1d5852', 108, 'admin', '2026-05-06 20:20:54'),
(9, '4d5a79eb-a5bb-4fe1-92d1-8d133f1d5852', 4, 'member', '2026-05-06 20:30:48'),
(10, 'fbd18cfd-8447-4464-981f-c4da072c0b8a', 107, 'member', '2026-05-06 20:38:59'),
(12, '4d5a79eb-a5bb-4fe1-92d1-8d133f1d5852', 107, 'member', '2026-05-06 20:52:32');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tinnhan_nhom`
--

CREATE TABLE `tinnhan_nhom` (
  `maTinNhanNhom` int(11) NOT NULL,
  `maNhom` varchar(36) NOT NULL,
  `maNguoiGui` int(11) NOT NULL,
  `tenNguoiGui` varchar(255) NOT NULL,
  `noiDung` text DEFAULT NULL,
  `hinhAnh` varchar(512) DEFAULT NULL,
  `thoiGianTao` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `toanha`
--

CREATE TABLE `toanha` (
  `maToaNha` int(11) NOT NULL,
  `tenToaNha` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `toanha`
--

INSERT INTO `toanha` (`maToaNha`, `tenToaNha`) VALUES
(1, 'Tòa A'),
(2, 'Tòa B'),
(3, 'Tòa C'),
(4, 'Tòa D'),
(5, 'Tòa E'),
(6, 'Tòa F');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `vaitro`
--

CREATE TABLE `vaitro` (
  `maVaiTro` int(11) NOT NULL,
  `tenVaiTro` varchar(50) NOT NULL COMMENT 'khachHang, nhanVienCanTin, nhanVienGiaoHang'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `vaitro`
--

INSERT INTO `vaitro` (`maVaiTro`, `tenVaiTro`) VALUES
(1, 'khachHang'),
(2, 'nhanVienCanTin'),
(3, 'nhanVienGiaoHang');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `vi_ca_nhan`
--

CREATE TABLE `vi_ca_nhan` (
  `id` int(11) NOT NULL,
  `maTaiKhoan` int(11) NOT NULL,
  `soDu` decimal(15,2) DEFAULT 0.00,
  `capNhatLuc` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  ADD PRIMARY KEY (`maChiTietDonHang`),
  ADD KEY `maDonHang` (`maDonHang`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Chỉ mục cho bảng `danhgia`
--
ALTER TABLE `danhgia`
  ADD PRIMARY KEY (`maDanhGia`),
  ADD KEY `maDonHang` (`maDonHang`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Chỉ mục cho bảng `danhmuc`
--
ALTER TABLE `danhmuc`
  ADD PRIMARY KEY (`maDanhMuc`);

--
-- Chỉ mục cho bảng `donhang`
--
ALTER TABLE `donhang`
  ADD PRIMARY KEY (`maDonHang`),
  ADD KEY `maTaiKhoan` (`maTaiKhoan`),
  ADD KEY `maNhomGiaoHang` (`maNhomGiaoHang`),
  ADD KEY `donhang_toanha_fk` (`maToaNha`),
  ADD KEY `donhang_phong_fk` (`maPhong`);

--
-- Chỉ mục cho bảng `giamgia`
--
ALTER TABLE `giamgia`
  ADD PRIMARY KEY (`maGiamGia`),
  ADD KEY `idx_gianhang` (`maGianHang`),
  ADD KEY `idx_monan` (`maMonAn`),
  ADD KEY `idx_active` (`trangThai`,`thoiGianKetThuc`);

--
-- Chỉ mục cho bảng `giamgia_daluu`
--
ALTER TABLE `giamgia_daluu`
  ADD PRIMARY KEY (`maGiamGiaDaLuu`),
  ADD UNIQUE KEY `uq_user_giamgia` (`maTaiKhoan`,`maGiamGia`),
  ADD KEY `idx_user` (`maTaiKhoan`),
  ADD KEY `idx_giamgia` (`maGiamGia`);

--
-- Chỉ mục cho bảng `gianhang`
--
ALTER TABLE `gianhang`
  ADD PRIMARY KEY (`maGianHang`),
  ADD KEY `maTaiKhoan` (`maTaiKhoan`);

--
-- Chỉ mục cho bảng `giao_dich_vi`
--
ALTER TABLE `giao_dich_vi`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `giohang`
--
ALTER TABLE `giohang`
  ADD PRIMARY KEY (`maTaiKhoan`,`maMonAn`),
  ADD KEY `maMonAn` (`maMonAn`);

--
-- Chỉ mục cho bảng `monan`
--
ALTER TABLE `monan`
  ADD PRIMARY KEY (`maMonAn`),
  ADD KEY `maGianHang` (`maGianHang`),
  ADD KEY `maDanhMuc` (`maDanhMuc`);

--
-- Chỉ mục cho bảng `nhom`
--
ALTER TABLE `nhom`
  ADD PRIMARY KEY (`maNhom`),
  ADD UNIQUE KEY `uq_maMoi` (`maMoi`),
  ADD KEY `fk_nhom_nguoi_tao` (`maNguoiTao`);

--
-- Chỉ mục cho bảng `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  ADD PRIMARY KEY (`maNhomGiaoHang`),
  ADD KEY `nhomgiaohang_toanha_fk` (`maToaNha`);

--
-- Chỉ mục cho bảng `phong`
--
ALTER TABLE `phong`
  ADD PRIMARY KEY (`maPhong`),
  ADD KEY `phong_toanha_fk` (`maToaNha`);

--
-- Chỉ mục cho bảng `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD PRIMARY KEY (`maTaiKhoan`),
  ADD UNIQUE KEY `tenDangNhap` (`tenDangNhap`),
  ADD KEY `maVaiTro` (`maVaiTro`);

--
-- Chỉ mục cho bảng `thanhtoan`
--
ALTER TABLE `thanhtoan`
  ADD PRIMARY KEY (`maTT`),
  ADD UNIQUE KEY `txnRef` (`txnRef`),
  ADD KEY `fk_tt_donhang` (`maDonHang`);

--
-- Chỉ mục cho bảng `thanhvien_nhom`
--
ALTER TABLE `thanhvien_nhom`
  ADD PRIMARY KEY (`maThanhVienNhom`),
  ADD UNIQUE KEY `uq_nhom_taikhoan` (`maNhom`,`maTaiKhoan`),
  ADD KEY `idx_maNhom` (`maNhom`),
  ADD KEY `idx_maTaiKhoan` (`maTaiKhoan`);

--
-- Chỉ mục cho bảng `tinnhan_nhom`
--
ALTER TABLE `tinnhan_nhom`
  ADD PRIMARY KEY (`maTinNhanNhom`),
  ADD KEY `idx_tnn_nhom` (`maNhom`),
  ADD KEY `idx_tnn_nguoi_gui` (`maNguoiGui`);

--
-- Chỉ mục cho bảng `toanha`
--
ALTER TABLE `toanha`
  ADD PRIMARY KEY (`maToaNha`);

--
-- Chỉ mục cho bảng `vaitro`
--
ALTER TABLE `vaitro`
  ADD PRIMARY KEY (`maVaiTro`);

--
-- Chỉ mục cho bảng `vi_ca_nhan`
--
ALTER TABLE `vi_ca_nhan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `maTaiKhoan` (`maTaiKhoan`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  MODIFY `maChiTietDonHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5006;

--
-- AUTO_INCREMENT cho bảng `danhgia`
--
ALTER TABLE `danhgia`
  MODIFY `maDanhGia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=502;

--
-- AUTO_INCREMENT cho bảng `danhmuc`
--
ALTER TABLE `danhmuc`
  MODIFY `maDanhMuc` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `donhang`
--
ALTER TABLE `donhang`
  MODIFY `maDonHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=504;

--
-- AUTO_INCREMENT cho bảng `giamgia`
--
ALTER TABLE `giamgia`
  MODIFY `maGiamGia` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT cho bảng `giamgia_daluu`
--
ALTER TABLE `giamgia_daluu`
  MODIFY `maGiamGiaDaLuu` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT cho bảng `gianhang`
--
ALTER TABLE `gianhang`
  MODIFY `maGianHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `giao_dich_vi`
--
ALTER TABLE `giao_dich_vi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT cho bảng `monan`
--
ALTER TABLE `monan`
  MODIFY `maMonAn` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT cho bảng `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  MODIFY `maNhomGiaoHang` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT cho bảng `phong`
--
ALTER TABLE `phong`
  MODIFY `maPhong` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT cho bảng `taikhoan`
--
ALTER TABLE `taikhoan`
  MODIFY `maTaiKhoan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT cho bảng `thanhtoan`
--
ALTER TABLE `thanhtoan`
  MODIFY `maTT` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT cho bảng `thanhvien_nhom`
--
ALTER TABLE `thanhvien_nhom`
  MODIFY `maThanhVienNhom` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT cho bảng `tinnhan_nhom`
--
ALTER TABLE `tinnhan_nhom`
  MODIFY `maTinNhanNhom` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `toanha`
--
ALTER TABLE `toanha`
  MODIFY `maToaNha` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `vaitro`
--
ALTER TABLE `vaitro`
  MODIFY `maVaiTro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `vi_ca_nhan`
--
ALTER TABLE `vi_ca_nhan`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `chitietdonhang`
--
ALTER TABLE `chitietdonhang`
  ADD CONSTRAINT `chitietdonhang_ibfk_1` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`),
  ADD CONSTRAINT `chitietdonhang_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`);

--
-- Các ràng buộc cho bảng `danhgia`
--
ALTER TABLE `danhgia`
  ADD CONSTRAINT `danhgia_ibfk_1` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`),
  ADD CONSTRAINT `danhgia_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`);

--
-- Các ràng buộc cho bảng `donhang`
--
ALTER TABLE `donhang`
  ADD CONSTRAINT `donhang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`),
  ADD CONSTRAINT `donhang_ibfk_2` FOREIGN KEY (`maNhomGiaoHang`) REFERENCES `nhomgiaohang` (`maNhomGiaoHang`),
  ADD CONSTRAINT `donhang_phong_fk` FOREIGN KEY (`maPhong`) REFERENCES `phong` (`maPhong`),
  ADD CONSTRAINT `donhang_toanha_fk` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`);

--
-- Các ràng buộc cho bảng `giamgia`
--
ALTER TABLE `giamgia`
  ADD CONSTRAINT `giamgia_ibfk_gianhang` FOREIGN KEY (`maGianHang`) REFERENCES `gianhang` (`maGianHang`) ON DELETE CASCADE,
  ADD CONSTRAINT `giamgia_ibfk_monan` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `giamgia_daluu`
--
ALTER TABLE `giamgia_daluu`
  ADD CONSTRAINT `gd_ibfk_giamgia` FOREIGN KEY (`maGiamGia`) REFERENCES `giamgia` (`maGiamGia`) ON DELETE CASCADE,
  ADD CONSTRAINT `gd_ibfk_taikhoan` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `gianhang`
--
ALTER TABLE `gianhang`
  ADD CONSTRAINT `gianhang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`);

--
-- Các ràng buộc cho bảng `giohang`
--
ALTER TABLE `giohang`
  ADD CONSTRAINT `giohang_ibfk_1` FOREIGN KEY (`maTaiKhoan`) REFERENCES `taikhoan` (`maTaiKhoan`) ON DELETE CASCADE,
  ADD CONSTRAINT `giohang_ibfk_2` FOREIGN KEY (`maMonAn`) REFERENCES `monan` (`maMonAn`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `monan`
--
ALTER TABLE `monan`
  ADD CONSTRAINT `monan_ibfk_1` FOREIGN KEY (`maGianHang`) REFERENCES `gianhang` (`maGianHang`),
  ADD CONSTRAINT `monan_ibfk_2` FOREIGN KEY (`maDanhMuc`) REFERENCES `danhmuc` (`maDanhMuc`) ON DELETE SET NULL;

--
-- Các ràng buộc cho bảng `nhomgiaohang`
--
ALTER TABLE `nhomgiaohang`
  ADD CONSTRAINT `nhomgiaohang_toanha_fk` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`);

--
-- Các ràng buộc cho bảng `phong`
--
ALTER TABLE `phong`
  ADD CONSTRAINT `phong_toanha_fk` FOREIGN KEY (`maToaNha`) REFERENCES `toanha` (`maToaNha`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `taikhoan`
--
ALTER TABLE `taikhoan`
  ADD CONSTRAINT `taikhoan_ibfk_1` FOREIGN KEY (`maVaiTro`) REFERENCES `vaitro` (`maVaiTro`);

--
-- Các ràng buộc cho bảng `thanhtoan`
--
ALTER TABLE `thanhtoan`
  ADD CONSTRAINT `fk_tt_donhang` FOREIGN KEY (`maDonHang`) REFERENCES `donhang` (`maDonHang`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `thanhvien_nhom`
--
ALTER TABLE `thanhvien_nhom`
  ADD CONSTRAINT `fk_tvn_nhom` FOREIGN KEY (`maNhom`) REFERENCES `nhom` (`maNhom`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `tinnhan_nhom`
--
ALTER TABLE `tinnhan_nhom`
  ADD CONSTRAINT `fk_tnn_nhom` FOREIGN KEY (`maNhom`) REFERENCES `nhom` (`maNhom`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
