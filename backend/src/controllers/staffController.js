const {
  listDishCategories,
  createDishCategory,
  updateDishCategory,
  deleteDishCategory,
  listMenu,
  createDish,
  updateDish,
  updateDishImage,
  deleteDish,
  getMyCanteen,
  updateMyCanteen,
  listPromotions,
  createPromotion,
  updatePromotion,
  deletePromotion,
  listOrderRequests,
  updateOrderStatus,
  getOrderStatsByDish,
} = require("../services/staffService");
const { saveCroppedDishImage } = require("../config/upload");

async function getMenu(req, res, next) {
  try {
    const rows = await listMenu(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function getCategories(req, res, next) {
  try {
    const rows = await listDishCategories(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function addCategory(req, res, next) {
  try {
    const category = await createDishCategory(req.auth, req.body);
    res.status(201).json(category);
  } catch (error) {
    next(error);
  }
}

async function editCategory(req, res, next) {
  try {
    const category = await updateDishCategory(req.auth, req.params.categoryId, req.body);
    res.json(category);
  } catch (error) {
    next(error);
  }
}

async function removeCategory(req, res, next) {
  try {
    const result = await deleteDishCategory(req.auth, req.params.categoryId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function addDish(req, res, next) {
  try {
    const dish = await createDish(req.auth, req.body);
    res.status(201).json(dish);
  } catch (error) {
    next(error);
  }
}

async function editDish(req, res, next) {
  try {
    const dish = await updateDish(req.auth, req.params.dishId, req.body);
    res.json(dish);
  } catch (error) {
    next(error);
  }
}

async function removeDish(req, res, next) {
  try {
    const result = await deleteDish(req.auth, req.params.dishId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getCanteen(req, res, next) {
  try {
    const canteen = await getMyCanteen(req.auth);
    res.json(canteen);
  } catch (error) {
    next(error);
  }
}

async function updateCanteen(req, res, next) {
  try {
    const canteen = await updateMyCanteen(req.auth, req.body);
    res.json(canteen);
  } catch (error) {
    next(error);
  }
}

async function getPromotions(req, res, next) {
  try {
    const rows = await listPromotions(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function addPromotion(req, res, next) {
  try {
    const promotion = await createPromotion(req.auth, req.body);
    res.status(201).json(promotion);
  } catch (error) {
    next(error);
  }
}

async function editPromotion(req, res, next) {
  try {
    const promotion = await updatePromotion(req.auth, req.params.promotionId, req.body);
    res.json(promotion);
  } catch (error) {
    next(error);
  }
}

async function removePromotion(req, res, next) {
  try {
    const result = await deletePromotion(req.auth, req.params.promotionId);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getOrders(req, res, next) {
  try {
    const rows = await listOrderRequests(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function editOrderStatus(req, res, next) {
  try {
    const order = await updateOrderStatus(req.auth, req.params.orderId, req.body);
    res.json(order);
  } catch (error) {
    next(error);
  }
}

async function getDishOrderStats(req, res, next) {
  try {
    const rows = await getOrderStatsByDish(req.auth);
    res.json(rows);
  } catch (error) {
    next(error);
  }
}

async function uploadDishImage(req, res, next) {
  try {
    if (!req.file) {
      const error = new Error("Ban chua chon anh mon an.");
      error.statusCode = 400;
      throw error;
    }

    const uploaded = await saveCroppedDishImage(req.file.buffer);
    const dishId = Number(req.params.dishId);

    if (Number.isInteger(dishId) && dishId > 0) {
      const dish = await updateDishImage(req.auth, dishId, uploaded.publicPath);
      res.json({
        imageUrl: uploaded.publicPath,
        dish,
      });
      return;
    }

    res.json({ imageUrl: uploaded.publicPath });
  } catch (error) {
    next(error);
  }
}

// ── Promotion CRUD (dùng bảng gianhang thực tế) ──────────────────────────────
const { query } = require('../config/db');

/** Lấy tất cả voucher của gian hàng mình */
async function getPromotions(req, res, next) {
  try {
    const staffId = req.user?.maTaiKhoan;   // verifyToken sets req.user
    if (!staffId) return res.status(401).json({ message: 'Chưa đăng nhập.' });
    const storeRows = await query(
      'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ? LIMIT 1',
      [staffId]
    );
    if (storeRows.length === 0) return res.json([]);
    const maGianHang = storeRows[0].maGianHang;

    const rows = await query(`
      SELECT
        gg.maGiamGia        AS id,
        gg.maGianHang       AS canteenId,
        g.tenGianHang       AS canteenName,
        gg.maMonAn          AS dishId,
        m.tenMonAn          AS dishName,
        gg.maVoucher        AS code,
        gg.tenGiamGia       AS title,
        gg.moTa             AS description,
        gg.phanTramGiam     AS discountPercent,
        gg.hinhAnhBanner    AS bannerImageUrl,
        gg.soLanToiDa       AS maxUses,
        gg.soLanDaDung      AS usedCount,
        gg.thoiGianBatDau   AS startsAt,
        gg.thoiGianKetThuc  AS endsAt,
        gg.trangThai        AS isActive,
        gg.thoiGianTao      AS createdAt
      FROM giamgia gg
      INNER JOIN gianhang g ON g.maGianHang = gg.maGianHang
      LEFT  JOIN monan    m ON m.maMonAn    = gg.maMonAn
      WHERE gg.maGianHang = ?
      ORDER BY gg.thoiGianTao DESC
    `, [maGianHang]);
    res.json(rows);
  } catch (error) { next(error); }
}

/** Tạo voucher mới */
async function addPromotion(req, res, next) {
  try {
    const staffId = req.user?.maTaiKhoan;   // verifyToken sets req.user
    if (!staffId) return res.status(401).json({ message: 'Chưa đăng nhập.' });
    const storeRows = await query(
      'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ? LIMIT 1',
      [staffId]
    );
    if (storeRows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy gian hàng.' });
    }
    const maGianHang = storeRows[0].maGianHang;
    const { title, code, discountPercent, endsAt, description, isActive,
      maMonAn, maxUses } = req.body;

    const result = await query(`
      INSERT INTO giamgia
        (maGianHang, maMonAn, maVoucher, tenGiamGia, moTa, phanTramGiam, soLanToiDa, thoiGianKetThuc, trangThai)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      maGianHang,
      maMonAn != null ? Number(maMonAn) : null,
      code ?? null,
      title,
      description ?? null,
      discountPercent ?? 0,
      maxUses != null ? Number(maxUses) : null,
      endsAt,
      isActive !== false ? 1 : 0,
    ]);

    res.status(201).json({ id: result.insertId, message: 'Tạo voucher thành công.' });
  } catch (error) { next(error); }
}

/** Sửa voucher */
async function editPromotion(req, res, next) {
  try {
    const staffId = req.user?.maTaiKhoan;   // verifyToken sets req.user
    if (!staffId) return res.status(401).json({ message: 'Chưa đăng nhập.' });
    const promotionId = Number(req.params.promotionId);
    const storeRows = await query(
      'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ? LIMIT 1',
      [staffId]
    );
    if (storeRows.length === 0) return res.status(404).json({ message: 'Không tìm thấy gian hàng.' });
    const maGianHang = storeRows[0].maGianHang;

    const { title, code, discountPercent, endsAt, description, isActive,
      maMonAn, maxUses } = req.body;
    await query(`
      UPDATE giamgia
      SET tenGiamGia = ?, maVoucher = ?, moTa = ?,
          phanTramGiam = ?, soLanToiDa = ?, thoiGianKetThuc = ?,
          maMonAn = ?, trangThai = ?
      WHERE maGiamGia = ? AND maGianHang = ?
    `, [
      title,
      code ?? null,
      description ?? null,
      discountPercent ?? 0,
      maxUses != null ? Number(maxUses) : null,
      endsAt,
      maMonAn != null ? Number(maMonAn) : null,
      isActive !== false ? 1 : 0,
      promotionId,
      maGianHang,
    ]);

    res.json({ message: 'Cập nhật voucher thành công.' });
  } catch (error) { next(error); }
}

/** Xoá voucher */
async function removePromotion(req, res, next) {
  try {
    const staffId = req.user?.maTaiKhoan;   // verifyToken sets req.user
    if (!staffId) return res.status(401).json({ message: 'Chưa đăng nhập.' });
    const promotionId = Number(req.params.promotionId);
    const storeRows = await query(
      'SELECT maGianHang FROM gianhang WHERE maTaiKhoan = ? LIMIT 1',
      [staffId]
    );
    if (storeRows.length === 0) return res.status(404).json({ message: 'Không tìm thấy gian hàng.' });
    const maGianHang = storeRows[0].maGianHang;

    await query('DELETE FROM giamgia WHERE maGiamGia = ? AND maGianHang = ?',
      [promotionId, maGianHang]);
    res.json({ message: 'Đã xoá voucher.' });
  } catch (error) { next(error); }
}

module.exports = {
  getCategories,
  addCategory,
  editCategory,
  removeCategory,
  getMenu,
  addDish,
  editDish,
  removeDish,
  getCanteen,
  updateCanteen,
  getPromotions,
  addPromotion,
  editPromotion,
  removePromotion,
  getOrders,
  editOrderStatus,
  getDishOrderStats,
  uploadDishImage,
};
