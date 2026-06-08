-- =====================================================================
-- Migration: Tạo bảng giohang_nhom (Group Cart)
-- Chạy script này trong phpMyAdmin → database canteen
-- =====================================================================

CREATE TABLE IF NOT EXISTS `giohang_nhom` (
  `maGioHangNhom` int(11) NOT NULL AUTO_INCREMENT,
  `maNhom`        varchar(36) NOT NULL COMMENT 'FK → nhom.maNhom',
  `maTaiKhoan`    int(11) NOT NULL COMMENT 'Người thêm món',
  `maMonAn`       int(11) NOT NULL,
  `soLuong`       int(11) NOT NULL DEFAULT 1,
  `ghiChu`        varchar(255) DEFAULT NULL COMMENT 'Ghi chú món (VD: ít cay)',
  `thoiGianThem`  datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`maGioHangNhom`),
  INDEX `idx_gcn_nhom`  (`maNhom`),
  INDEX `idx_gcn_user`  (`maTaiKhoan`),
  INDEX `idx_gcn_mon`   (`maMonAn`),
  CONSTRAINT `fk_gcn_nhom` FOREIGN KEY (`maNhom`)
    REFERENCES `nhom` (`maNhom`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_gcn_user` FOREIGN KEY (`maTaiKhoan`)
    REFERENCES `taikhoan` (`maTaiKhoan`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_gcn_mon`  FOREIGN KEY (`maMonAn`)
    REFERENCES `monan` (`maMonAn`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Giỏ hàng chung của nhóm — mỗi thành viên thêm món cho mình';
