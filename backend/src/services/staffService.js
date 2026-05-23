const { query } = require("../config/db");

function buildError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeText(value) {
  return String(value || "").trim();
}

function normalizeOptionalText(value) {
  const normalized = normalizeText(value);
  return normalized ? normalized : null;
}

function ensureStaffCanteen(auth) {
  const canteenId = Number(auth.canteenId);

  if (!Number.isInteger(canteenId) || canteenId <= 0) {
    throw buildError("Tai khoan nhan vien chua duoc gan gian hang.", 400);
  }

  return canteenId;
}

async function ensurePromotionsTableCompatibility() {
  await query(
    `
      ALTER TABLE giamgia
      ADD COLUMN IF NOT EXISTS maMonAn INT NULL AFTER maGianHang,
      ADD COLUMN IF NOT EXISTS maVoucher VARCHAR(40) NULL AFTER maMonAn
    `,
  );
}

async function ensureCategoriesTable() {
  await query(
    `
      CREATE TABLE IF NOT EXISTS canteen_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        canteen_id INT NOT NULL,
        name VARCHAR(80) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_canteen_category (canteen_id, name),
        CONSTRAINT fk_category_canteen FOREIGN KEY (canteen_id) REFERENCES canteens(id) ON DELETE CASCADE
      )
    `,
  );

  // Ensure compatibility with databases created before updated_at existed.
  await query(
    `
      ALTER TABLE canteen_categories
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    `,
  );
}

async function ensureDefaultCategory(canteenId) {
  await ensureCategoriesTable();
  await query(
    `
      INSERT INTO canteen_categories (canteen_id, name)
      VALUES (?, 'Khac')
      ON DUPLICATE KEY UPDATE name = VALUES(name)
    `,
    [canteenId],
  );
}

async function ensureCategoryExists(canteenId, categoryName) {
  await ensureDefaultCategory(canteenId);
  await query(
    `
      INSERT INTO canteen_categories (canteen_id, name)
      VALUES (?, ?)
      ON DUPLICATE KEY UPDATE name = VALUES(name)
    `,
    [canteenId, categoryName],
  );
}

async function listDishCategories(auth) {
  const canteenId = ensureStaffCanteen(auth);
  await ensureDefaultCategory(canteenId);

  // Keep category table in sync with categories already stored on dishes.
  await query(
    `
      INSERT INTO canteen_categories (canteen_id, name)
      SELECT d.canteen_id, d.category_name
      FROM dishes d
      WHERE d.canteen_id = ?
        AND TRIM(COALESCE(d.category_name, '')) <> ''
      GROUP BY d.canteen_id, d.category_name
      ON DUPLICATE KEY UPDATE name = VALUES(name)
    `,
    [canteenId],
  );

  const rows = await query(
    `
      SELECT
        id,
        name,
        created_at AS createdAt
      FROM canteen_categories
      WHERE canteen_id = ?
      ORDER BY CASE WHEN name = 'Khac' THEN 0 ELSE 1 END, name ASC
    `,
    [canteenId],
  );

  return rows;
}

async function createDishCategory(auth, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const name = normalizeText(payload.name);

  if (!name) {
    throw buildError('Ten danh muc la bat buoc.', 400);
  }

  await ensureDefaultCategory(canteenId);

  const existedRows = await query(
    `
      SELECT
        id,
        name,
        created_at AS createdAt
      FROM canteen_categories
      WHERE canteen_id = ?
        AND LOWER(TRIM(name)) = LOWER(TRIM(?))
      LIMIT 1
    `,
    [canteenId, name],
  );

  if (existedRows.length > 0) {
    return existedRows[0];
  }

  const result = await query(
    `
      INSERT INTO canteen_categories (canteen_id, name)
      VALUES (?, ?)
    `,
    [canteenId, name],
  );

  const rows = await query(
    `
      SELECT
        id,
        name,
        created_at AS createdAt
      FROM canteen_categories
      WHERE id = ?
      LIMIT 1
    `,
    [result.insertId],
  );

  return rows[0];
}

async function updateDishCategory(auth, categoryIdInput, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const categoryId = Number(categoryIdInput);
  const nextName = normalizeText(payload.name);

  if (!Number.isInteger(categoryId) || categoryId <= 0) {
    throw buildError('Danh muc khong hop le.', 400);
  }

  if (!nextName) {
    throw buildError('Ten danh muc la bat buoc.', 400);
  }

  const rows = await query(
    `
      SELECT id, name
      FROM canteen_categories
      WHERE id = ?
        AND canteen_id = ?
      LIMIT 1
    `,
    [categoryId, canteenId],
  );

  if (rows.length === 0) {
    throw buildError('Khong tim thay danh muc.', 404);
  }

  const currentName = rows[0].name;

  await query(
    `
      UPDATE canteen_categories
      SET name = ?
      WHERE id = ?
        AND canteen_id = ?
    `,
    [nextName, categoryId, canteenId],
  );

  await query(
    `
      UPDATE dishes
      SET category_name = ?
      WHERE canteen_id = ?
        AND category_name = ?
    `,
    [nextName, canteenId, currentName],
  );

  const updated = await query(
    `
      SELECT
        id,
        name,
        created_at AS createdAt
      FROM canteen_categories
      WHERE id = ?
      LIMIT 1
    `,
    [categoryId],
  );

  return updated[0];
}

async function deleteDishCategory(auth, categoryIdInput) {
  const canteenId = ensureStaffCanteen(auth);
  const categoryId = Number(categoryIdInput);

  if (!Number.isInteger(categoryId) || categoryId <= 0) {
    throw buildError('Danh muc khong hop le.', 400);
  }

  const rows = await query(
    `
      SELECT id, name
      FROM canteen_categories
      WHERE id = ?
        AND canteen_id = ?
      LIMIT 1
    `,
    [categoryId, canteenId],
  );

  if (rows.length === 0) {
    throw buildError('Khong tim thay danh muc.', 404);
  }

  const categoryName = rows[0].name;
  if (categoryName === 'Khac') {
    throw buildError('Khong the xoa danh muc mac dinh Khac.', 400);
  }

  await ensureDefaultCategory(canteenId);

  await query(
    `
      UPDATE dishes
      SET category_name = 'Khac'
      WHERE canteen_id = ?
        AND category_name = ?
    `,
    [canteenId, categoryName],
  );

  await query(
    `
      DELETE FROM canteen_categories
      WHERE id = ?
        AND canteen_id = ?
    `,
    [categoryId, canteenId],
  );

  return {
    message: 'Da xoa danh muc.',
  };
}

async function listMenu(auth) {
  const canteenId = ensureStaffCanteen(auth);

  return query(
    `
      SELECT
        id,
        category_name AS categoryName,
        name,
        description,
        price,
        image_url AS imageUrl,
        is_available AS isAvailable,
        created_at AS createdAt
      FROM dishes
      WHERE canteen_id = ?
      ORDER BY created_at DESC
    `,
    [canteenId],
  );
}

async function createDish(auth, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const name = normalizeText(payload.name);
  const categoryName = normalizeText(payload.categoryName || "Khac");
  const description = normalizeOptionalText(payload.description);
  const imageUrl = normalizeOptionalText(payload.imageUrl);
  const price = Number(payload.price);
  const isAvailable = payload.isAvailable !== false;

  if (!name || !Number.isFinite(price) || price <= 0) {
    throw buildError("Ten mon va gia ban hop le la bat buoc.", 400);
  }

  const result = await query(
    `
      INSERT INTO dishes (canteen_id, category_name, name, description, price, image_url, is_available)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `,
    [canteenId, categoryName, name, description, price, imageUrl, isAvailable],
  );

  const rows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        category_name AS categoryName,
        name,
        description,
        price,
        image_url AS imageUrl,
        is_available AS isAvailable
      FROM dishes
      WHERE id = ?
      LIMIT 1
    `,
    [result.insertId],
  );

  return rows[0];
}

async function updateDish(auth, dishIdInput, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const dishId = Number(dishIdInput);
  const name = normalizeText(payload.name);
  const categoryName = normalizeText(payload.categoryName || "Khac");
  const description = normalizeOptionalText(payload.description);
  const imageUrl = normalizeOptionalText(payload.imageUrl);
  const price = Number(payload.price);
  const isAvailable = payload.isAvailable !== false;

  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  if (!name || !Number.isFinite(price) || price <= 0) {
    throw buildError("Ten mon va gia ban hop le la bat buoc.", 400);
  }

  const result = await query(
    `
      UPDATE dishes
      SET category_name = ?,
          name = ?,
          description = ?,
          price = ?,
          image_url = ?,
          is_available = ?
      WHERE id = ?
        AND canteen_id = ?
    `,
    [categoryName, name, description, price, imageUrl, isAvailable, dishId, canteenId],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay mon an de cap nhat.", 404);
  }

  const rows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        category_name AS categoryName,
        name,
        description,
        price,
        image_url AS imageUrl,
        is_available AS isAvailable
      FROM dishes
      WHERE id = ?
      LIMIT 1
    `,
    [dishId],
  );

  return rows[0];
}

async function updateDishImage(auth, dishIdInput, imageUrlInput) {
  const canteenId = ensureStaffCanteen(auth);
  const dishId = Number(dishIdInput);
  const imageUrl = normalizeOptionalText(imageUrlInput);

  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  if (!imageUrl) {
    throw buildError("Duong dan anh mon an khong hop le.", 400);
  }

  const result = await query(
    `
      UPDATE dishes
      SET image_url = ?
      WHERE id = ?
        AND canteen_id = ?
    `,
    [imageUrl, dishId, canteenId],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay mon an de cap nhat anh.", 404);
  }

  const rows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        category_name AS categoryName,
        name,
        description,
        price,
        image_url AS imageUrl,
        is_available AS isAvailable
      FROM dishes
      WHERE id = ?
      LIMIT 1
    `,
    [dishId],
  );

  return rows[0];
}

async function deleteDish(auth, dishIdInput) {
  const canteenId = ensureStaffCanteen(auth);
  const dishId = Number(dishIdInput);

  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  const result = await query(
    `
      DELETE FROM dishes
      WHERE id = ?
        AND canteen_id = ?
    `,
    [dishId, canteenId],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay mon an de xoa.", 404);
  }

  return {
    message: "Da xoa mon an khoi thuc don.",
  };
}

async function getMyCanteen(auth) {
  const canteenId = ensureStaffCanteen(auth);

  const rows = await query(
    `
      SELECT
        id,
        name,
        location,
        open_hours AS openHours,
        description,
        logo_url AS logoUrl,
        banner_url AS bannerUrl,
        contact_phone AS contactPhone,
        contact_email AS contactEmail
      FROM canteens
      WHERE id = ?
      LIMIT 1
    `,
    [canteenId],
  );

  if (rows.length === 0) {
    throw buildError("Khong tim thay gian hang can tin.", 404);
  }

  return rows[0];
}

async function updateMyCanteen(auth, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const name = normalizeText(payload.name);
  const location = normalizeText(payload.location);
  const openHours = normalizeText(payload.openHours);
  const description = normalizeOptionalText(payload.description);
  const logoUrl = normalizeOptionalText(payload.logoUrl);
  const bannerUrl = normalizeOptionalText(payload.bannerUrl);
  const contactPhone = normalizeOptionalText(payload.contactPhone);
  const contactEmail = normalizeOptionalText(payload.contactEmail);

  if (!name || !location || !openHours) {
    throw buildError("Ten gian hang, vi tri va gio mo cua la bat buoc.", 400);
  }

  await query(
    `
      UPDATE canteens
      SET name = ?,
          location = ?,
          open_hours = ?,
          description = ?,
          logo_url = ?,
          banner_url = ?,
          contact_phone = ?,
          contact_email = ?
      WHERE id = ?
    `,
    [name, location, openHours, description, logoUrl, bannerUrl, contactPhone, contactEmail, canteenId],
  );

  return getMyCanteen(auth);
}

async function listPromotions(auth) {
  const canteenId = ensureStaffCanteen(auth);
  await ensurePromotionsTableCompatibility();

  return query(
    `
      SELECT
          gg.maGiamGia AS id,
          gg.maGianHang AS canteenId,
          gg.maMonAn AS dishId,
          m.tenMonAn AS dishName,
          gg.maVoucher AS code,
          gg.tenGiamGia AS title,
          gg.moTa AS description,
          gg.phanTramGiam AS discountPercent,
          gg.hinhAnhBanner AS bannerImageUrl,
          gg.thoiGianBatDau AS startsAt,
          gg.thoiGianKetThuc AS endsAt,
          gg.trangThai AS isActive,
          gg.thoiGianTao AS createdAt,
          gg.thoiGianCapNhat AS updatedAt
        FROM giamgia gg
        LEFT JOIN monan m ON m.maMonAn = gg.maMonAn
        WHERE gg.maGianHang = ?
        ORDER BY gg.thoiGianTao DESC
    `,
    [canteenId],
  );
}

async function createPromotion(auth, payload) {
  const canteenId = ensureStaffCanteen(auth);
  await ensurePromotionsTableCompatibility();
  const dishId = payload.dishId == null ? null : Number(payload.dishId);
  const code = normalizeOptionalText(payload.code)?.toUpperCase() ?? null;
  const title = normalizeText(payload.title);
  const description = normalizeOptionalText(payload.description);
  const discountPercent = payload.discountPercent ? Number(payload.discountPercent) : null;
  const bannerImageUrl = normalizeOptionalText(payload.bannerImageUrl);
  const startsAt = normalizeOptionalText(payload.startsAt);
  const endsAt = normalizeOptionalText(payload.endsAt);
  const isActive = payload.isActive !== false;

  if (!title) {
    throw buildError("Tieu de khuyen mai la bat buoc.", 400);
  }

  if (!endsAt) {
    throw buildError("Voucher phai co thoi han ket thuc.", 400);
  }

  if (dishId !== null && (!Number.isInteger(dishId) || dishId <= 0)) {
    throw buildError("San pham ap dung voucher khong hop le.", 400);
  }

  if (code !== null && code.length > 40) {
    throw buildError("Ma voucher toi da 40 ky tu.", 400);
  }

  if (discountPercent !== null && (!Number.isFinite(discountPercent) || discountPercent <= 0 || discountPercent > 100)) {
    throw buildError("Phan tram giam gia phai trong khoang 0-100.", 400);
  }

  const startsAtDate = startsAt == null ? new Date() : new Date(startsAt);
  const endsAtDate = new Date(endsAt);

  if (Number.isNaN(startsAtDate.getTime()) || Number.isNaN(endsAtDate.getTime())) {
    throw buildError("Thoi gian voucher khong hop le.", 400);
  }

  if (endsAtDate <= startsAtDate) {
    throw buildError("Thoi han voucher phai sau thoi diem bat dau.", 400);
  }

  if (dishId !== null) {
    const dishRows = await query(
      `
        SELECT maMonAn
        FROM monan
        WHERE maMonAn = ?
          AND maGianHang = ?
        LIMIT 1
      `,
      [dishId, canteenId],
    );

    if (dishRows.length === 0) {
      throw buildError("Mon an ap dung voucher khong ton tai trong gian hang.", 400);
    }
  }

  const result = await query(
    `
      INSERT INTO giamgia (
        maGianHang,
        maMonAn,
        maVoucher,
        tenGiamGia,
        moTa,
        phanTramGiam,
        hinhAnhBanner,
        thoiGianBatDau,
        thoiGianKetThuc,
        trangThai
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [
      canteenId,
      dishId,
      code,
      title,
      description,
      discountPercent,
      bannerImageUrl,
      startsAtDate,
      endsAtDate,
      isActive,
    ],
  );

  const rows = await query(
    `
      SELECT
        gg.maGiamGia AS id,
        gg.maGianHang AS canteenId,
        gg.maMonAn AS dishId,
        m.tenMonAn AS dishName,
        gg.maVoucher AS code,
        gg.tenGiamGia AS title,
        gg.moTa AS description,
        gg.phanTramGiam AS discountPercent,
        gg.hinhAnhBanner AS bannerImageUrl,
        gg.thoiGianBatDau AS startsAt,
        gg.thoiGianKetThuc AS endsAt,
        gg.trangThai AS isActive
      FROM giamgia gg
      LEFT JOIN monan m ON m.maMonAn = gg.maMonAn
      WHERE gg.maGiamGia = ?
      LIMIT 1
    `,
    [result.insertId],
  );

  return rows[0];
}

async function updatePromotion(auth, promotionIdInput, payload) {
  const canteenId = ensureStaffCanteen(auth);
  await ensurePromotionsTableCompatibility();
  const promotionId = Number(promotionIdInput);
  const dishId = payload.dishId == null ? null : Number(payload.dishId);
  const code = normalizeOptionalText(payload.code)?.toUpperCase() ?? null;
  const title = normalizeText(payload.title);
  const description = normalizeOptionalText(payload.description);
  const discountPercent = payload.discountPercent ? Number(payload.discountPercent) : null;
  const bannerImageUrl = normalizeOptionalText(payload.bannerImageUrl);
  const startsAt = normalizeOptionalText(payload.startsAt);
  const endsAt = normalizeOptionalText(payload.endsAt);
  const isActive = payload.isActive !== false;

  if (!Number.isInteger(promotionId) || promotionId <= 0) {
    throw buildError("Khuyen mai khong hop le.", 400);
  }

  if (!title) {
    throw buildError("Tieu de khuyen mai la bat buoc.", 400);
  }

  if (!endsAt) {
    throw buildError("Voucher phai co thoi han ket thuc.", 400);
  }

  if (dishId !== null && (!Number.isInteger(dishId) || dishId <= 0)) {
    throw buildError("San pham ap dung voucher khong hop le.", 400);
  }

  if (code !== null && code.length > 40) {
    throw buildError("Ma voucher toi da 40 ky tu.", 400);
  }

  if (discountPercent !== null && (!Number.isFinite(discountPercent) || discountPercent <= 0 || discountPercent > 100)) {
    throw buildError("Phan tram giam gia phai trong khoang 0-100.", 400);
  }

  const startsAtDate = startsAt == null ? new Date() : new Date(startsAt);
  const endsAtDate = new Date(endsAt);

  if (Number.isNaN(startsAtDate.getTime()) || Number.isNaN(endsAtDate.getTime())) {
    throw buildError("Thoi gian voucher khong hop le.", 400);
  }

  if (endsAtDate <= startsAtDate) {
    throw buildError("Thoi han voucher phai sau thoi diem bat dau.", 400);
  }

  if (dishId !== null) {
    const dishRows = await query(
      `
        SELECT maMonAn
        FROM monan
        WHERE maMonAn = ?
          AND maGianHang = ?
        LIMIT 1
      `,
      [dishId, canteenId],
    );

    if (dishRows.length === 0) {
      throw buildError("Mon an ap dung voucher khong ton tai trong gian hang.", 400);
    }
  }

  const result = await query(
    `
      UPDATE giamgia
      SET maMonAn = ?,
          maVoucher = ?,
          tenGiamGia = ?,
          moTa = ?,
          phanTramGiam = ?,
          hinhAnhBanner = ?,
          thoiGianBatDau = ?,
          thoiGianKetThuc = ?,
          trangThai = ?
      WHERE maGiamGia = ?
        AND maGianHang = ?
    `,
    [
      dishId,
      code,
      title,
      description,
      discountPercent,
      bannerImageUrl,
      startsAtDate,
      endsAtDate,
      isActive,
      promotionId,
      canteenId,
    ],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay khuyen mai de cap nhat.", 404);
  }

  const rows = await query(
    `
      SELECT
        gg.maGiamGia AS id,
        gg.maGianHang AS canteenId,
        gg.maMonAn AS dishId,
        m.tenMonAn AS dishName,
        gg.maVoucher AS code,
        gg.tenGiamGia AS title,
        gg.moTa AS description,
        gg.phanTramGiam AS discountPercent,
        gg.hinhAnhBanner AS bannerImageUrl,
        gg.thoiGianBatDau AS startsAt,
        gg.thoiGianKetThuc AS endsAt,
        gg.trangThai AS isActive
      FROM giamgia gg
      LEFT JOIN monan m ON m.maMonAn = gg.maMonAn
      WHERE gg.maGiamGia = ?
      LIMIT 1
    `,
    [promotionId],
  );

  return rows[0];
}

async function deletePromotion(auth, promotionIdInput) {
  const canteenId = ensureStaffCanteen(auth);
  await ensurePromotionsTableCompatibility();
  const promotionId = Number(promotionIdInput);

  if (!Number.isInteger(promotionId) || promotionId <= 0) {
    throw buildError("Voucher khong hop le.", 400);
  }

  const result = await query(
    `
      DELETE FROM giamgia
      WHERE maGiamGia = ?
        AND maGianHang = ?
    `,
    [promotionId, canteenId],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay voucher de xoa.", 404);
  }

  return {
    message: "Da xoa voucher.",
  };
}

async function listOrderRequests(auth) {
  const canteenId = ensureStaffCanteen(auth);

  return query(
    `
      SELECT
        o.id,
        o.group_order_id AS groupOrderId,
        o.dish_id AS dishId,
        d.name AS dishName,
        d.category_name AS categoryName,
        o.student_name AS studentName,
        o.student_phone AS studentPhone,
        o.quantity,
        o.note,
        o.delivery_point AS deliveryPoint,
        o.delivery_zone AS deliveryZone,
        o.delivery_time_slot AS deliveryTimeSlot,
        o.building_code AS buildingCode,
        o.floor,
        o.lat,
        o.lng,
        o.expires_at AS expiresAt,
        o.delivery_surcharge AS deliverySurcharge,
        o.cancellation_reason AS cancellationReason,
        o.line_total AS lineTotal,
        o.status,
        o.created_at AS createdAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      WHERE d.canteen_id = ?
      ORDER BY o.created_at DESC
      LIMIT 300
    `,
    [canteenId],
  );
}

async function updateOrderStatus(auth, orderIdInput, payload) {
  const canteenId = ensureStaffCanteen(auth);
  const orderId = Number(orderIdInput);
  const status = normalizeText(payload.status).toLowerCase();
  const allowedStatuses = [
    "pending",
    "grouped",
    "single_accepted",
    "confirmed",
    "delivered",
    "cancelled",
    "abort",
    "expired",
  ];

  if (!Number.isInteger(orderId) || orderId <= 0) {
    throw buildError("Don hang khong hop le.", 400);
  }

  if (!allowedStatuses.includes(status)) {
    throw buildError("Trang thai don hang khong hop le.", 400);
  }

  const result = await query(
    `
      UPDATE order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      SET o.status = ?
      WHERE o.id = ?
        AND d.canteen_id = ?
    `,
    [status, orderId, canteenId],
  );

  if (result.affectedRows === 0) {
    throw buildError("Khong tim thay don hang de cap nhat.", 404);
  }

  const rows = await query(
    `
      SELECT
        o.id,
        o.dish_id AS dishId,
        d.name AS dishName,
        d.category_name AS categoryName,
        o.student_name AS studentName,
        o.student_phone AS studentPhone,
        o.quantity,
        o.line_total AS lineTotal,
        o.status,
        o.created_at AS createdAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      WHERE o.id = ?
        AND d.canteen_id = ?
      LIMIT 1
    `,
    [orderId, canteenId],
  );

  return rows[0];
}

async function getOrderStatsByDish(auth) {
  const canteenId = ensureStaffCanteen(auth);

  return query(
    `
      SELECT
        d.id AS dishId,
        d.name AS dishName,
        COALESCE(COUNT(o.id), 0) AS totalOrders,
        COALESCE(SUM(o.quantity), 0) AS totalQuantity,
        COALESCE(SUM(o.line_total), 0) AS totalRevenue
      FROM dishes d
      LEFT JOIN order_requests o ON o.dish_id = d.id
      WHERE d.canteen_id = ?
      GROUP BY d.id, d.name
      ORDER BY totalQuantity DESC, d.name ASC
    `,
    [canteenId],
  );
}

module.exports = {
  listDishCategories,
  createDishCategory,
  updateDishCategory,
  deleteDishCategory,
  listMenu,
  createDish,
  updateDish,
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
  updateDishImage,
};
