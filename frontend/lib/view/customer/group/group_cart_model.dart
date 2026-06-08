// group_cart_model.dart — Model giỏ hàng nhóm
class GroupCartItem {
  final int maGioHangNhom;
  final String maNhom;
  final int maTaiKhoan;
  final int maMonAn;
  final int soLuong;
  final String? ghiChu;
  final String tenMonAn;
  final double giaTien;
  final String? hinhAnh;
  final int maGianHang;
  final String tenGianHang;
  final String tenNguoiThem;
  final String? anhNguoiThem;
  final DateTime? thoiGianThem;

  const GroupCartItem({
    required this.maGioHangNhom,
    required this.maNhom,
    required this.maTaiKhoan,
    required this.maMonAn,
    required this.soLuong,
    this.ghiChu,
    required this.tenMonAn,
    required this.giaTien,
    this.hinhAnh,
    required this.maGianHang,
    required this.tenGianHang,
    required this.tenNguoiThem,
    this.anhNguoiThem,
    this.thoiGianThem,
  });

  factory GroupCartItem.fromJson(Map<String, dynamic> j) {
    // Helper: parse số an toàn (xử lý cả String lẫn num từ MySQL decimal)
    int _int(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;
    double _dbl(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

    return GroupCartItem(
      maGioHangNhom: _int(j['maGioHangNhom']),
      maNhom: j['maNhom']?.toString() ?? '',
      maTaiKhoan: _int(j['maTaiKhoan']),
      maMonAn: _int(j['maMonAn']),
      soLuong: _int(j['soLuong']) == 0 ? 1 : _int(j['soLuong']),
      ghiChu: j['ghiChu']?.toString(),
      tenMonAn: j['tenMonAn']?.toString() ?? '',
      giaTien: _dbl(j['giaTien']),
      hinhAnh: j['hinhAnh']?.toString(),
      maGianHang: _int(j['maGianHang']),
      tenGianHang: j['tenGianHang']?.toString() ?? '',
      tenNguoiThem: j['tenNguoiThem']?.toString() ?? '',
      anhNguoiThem: j['anhNguoiThem']?.toString(),
      thoiGianThem: j['thoiGianThem'] == null ? null : DateTime.tryParse(j['thoiGianThem'].toString()),
    );
  }

  double get tongTien => giaTien * soLuong;

  GroupCartItem copyWith({int? soLuong}) => GroupCartItem(
        maGioHangNhom: maGioHangNhom,
        maNhom: maNhom,
        maTaiKhoan: maTaiKhoan,
        maMonAn: maMonAn,
        soLuong: soLuong ?? this.soLuong,
        ghiChu: ghiChu,
        tenMonAn: tenMonAn,
        giaTien: giaTien,
        hinhAnh: hinhAnh,
        maGianHang: maGianHang,
        tenGianHang: tenGianHang,
        tenNguoiThem: tenNguoiThem,
        anhNguoiThem: anhNguoiThem,
        thoiGianThem: thoiGianThem,
      );
}

