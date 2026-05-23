// wallet_constants.dart — Hằng số & tiện ích dùng chung trong ví cá nhân

/// Danh sách ngân hàng VN hỗ trợ rút tiền
const List<String> kBanks = [
  'Vietcombank',
  'BIDV',
  'Agribank',
  'Techcombank',
  'MB Bank',
  'VPBank',
  'ACB',
  'Sacombank',
  'VietinBank',
  'TPBank',
  'MSB',
  'VIB',
  'HDBank',
  'OCB',
];

/// Format số tiền VNĐ — VD: 1500000 → "1.500.000 đ"
String fmtVnd(double v) =>
    '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
