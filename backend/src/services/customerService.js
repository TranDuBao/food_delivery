const { query, withTransaction } = require("../config/db");
const bcrypt = require("bcryptjs");

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

function normalizePhone(value) {
  const raw = normalizeText(value).replaceAll(" ", "");
  if (!raw) {
    return null;
  }

  if (!/^\+?[0-9]{9,15}$/.test(raw)) {
    throw buildError("So dien thoai khong hop le.", 400);
  }

  return raw;
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

function calculateCustomerTier(totalOrders) {
  if (totalOrders > 5000) {
    return {
      code: "vip_king",
      label: "Khach hang VIP",
      icon: "king",
      minOrders: 5001,
      perks: [
        "Uu dai dac biet theo thang",
        "Ho tro uu tien",
        "Voucher doc quyen dinh ky",
      ],
    };
  }

  if (totalOrders > 1500) {
    return {
      code: "diamond",
      label: "Khach hang Kim Cuong",
      icon: "diamond",
      minOrders: 1501,
      perks: ["Uu tien flash sale", "Hoan xu cao hon", "Voucher sinh nhat dac biet"],
    };
  }

  if (totalOrders >= 500) {
    return {
      code: "gold",
      label: "Khach hang Vang",
      icon: "gold",
      minOrders: 500,
      perks: ["Giam gia them cho don lon", "Nhan voucher hang tuan"],
    };
  }

  if (totalOrders >= 100) {
    return {
      code: "silver",
      label: "Khach hang Bac",
      icon: "silver",
      minOrders: 100,
      perks: ["Nhan voucher hang thang", "Uu dai gio vang"],
    };
  }

  return {
    code: "regular",
    label: "Khach hang Thuong",
    icon: "regular",
    minOrders: 0,
    perks: ["Tich luy don de len hang Bac"],
  };
}

async function searchProducts({ q, canteenId }) {
  const keyword = normalizeText(q);
  const params = [];
  let sql = `
    SELECT
      d.id,
      d.canteen_id AS canteenId,
      c.name AS canteenName,
      d.category_name AS categoryName,
      d.name,
      d.description,
      d.price,
      d.image_url AS imageUrl,
      d.is_available AS isAvailable
    FROM dishes d
    INNER JOIN canteens c ON c.id = d.canteen_id
    WHERE 1 = 1
  `;

  if (keyword) {
    sql += " AND (d.name LIKE ? OR d.description LIKE ? OR c.name LIKE ?)";
    const likeKeyword = `%${keyword}%`;
    params.push(likeKeyword, likeKeyword, likeKeyword);
  }

  if (canteenId) {
    sql += " AND d.canteen_id = ?";
    params.push(Number(canteenId));
  }

  sql += " ORDER BY d.name ASC";

  return query(sql, params);
}

async function searchCanteens({ q }) {
  const keyword = normalizeText(q);
  const params = [];
  let sql = `
    SELECT
      c.id,
      c.name,
      c.location,
      c.open_hours AS openHours,
      c.description,
      c.logo_url AS logoUrl,
      c.banner_url AS bannerUrl,
      c.contact_phone AS contactPhone,
      c.contact_email AS contactEmail,
      COUNT(d.id) AS totalDishes
    FROM canteens c
    LEFT JOIN dishes d ON d.canteen_id = c.id AND d.is_available = TRUE
    WHERE 1 = 1
  `;

  if (keyword) {
    sql += " AND (c.name LIKE ? OR c.description LIKE ? OR c.location LIKE ?)";
    const likeKeyword = `%${keyword}%`;
    params.push(likeKeyword, likeKeyword, likeKeyword);
  }

  sql += `
    GROUP BY c.id
    ORDER BY c.name ASC
  `;

  return query(sql, params);
}

async function getProductDetail(productIdInput) {
  const productId = Number(productIdInput);

  if (!Number.isInteger(productId) || productId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  const rows = await query(
    `
      SELECT
        d.id,
        d.canteen_id AS canteenId,
        c.name AS canteenName,
        d.category_name AS categoryName,
        d.name,
        d.description,
        d.price,
        d.image_url AS imageUrl,
        d.is_available AS isAvailable
      FROM dishes d
      INNER JOIN canteens c ON c.id = d.canteen_id
      WHERE d.id = ?
      LIMIT 1
    `,
    [productId],
  );

  if (rows.length === 0) {
    throw buildError("Khong tim thay mon an.", 404);
  }

  return rows[0];
}

async function getCanteenDetail(canteenIdInput) {
  const canteenId = Number(canteenIdInput);

  if (!Number.isInteger(canteenId) || canteenId <= 0) {
    throw buildError("Gian hang can tin khong hop le.", 400);
  }

  const canteenRows = await query(
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

  if (canteenRows.length === 0) {
    throw buildError("Khong tim thay gian hang can tin.", 404);
  }

  const dishRows = await query(
    `
      SELECT
        id,
        name,
        description,
        price,
        image_url AS imageUrl,
        is_available AS isAvailable
      FROM dishes
      WHERE canteen_id = ?
      ORDER BY name ASC
    `,
    [canteenId],
  );

  return {
    ...canteenRows[0],
    dishes: dishRows,
  };
}

async function getCustomerProfile(userId) {
  const rows = await query(
    `
      SELECT
        id,
        full_name AS fullName,
        nickname,
        email,
        role,
        phone,
        avatar_url AS avatarUrl,
        canteen_id AS canteenId,
        created_at AS createdAt,
        updated_at AS updatedAt
      FROM users
      WHERE id = ?
      LIMIT 1
    `,
    [userId],
  );

  if (rows.length === 0) {
    throw buildError("Khong tim thay nguoi dung.", 404);
  }

  return rows[0];
}

async function updateCustomerProfile(userId, payload) {
  const fullName = normalizeText(payload.fullName);
  const nickname = normalizeOptionalText(payload.nickname);
  const phone = normalizePhone(payload.phone);
  const avatarUrl = normalizeOptionalText(payload.avatarUrl);

  if (!fullName) {
    throw buildError("Ho ten la bat buoc.", 400);
  }

  await query(
    `
      UPDATE users
      SET full_name = ?,
          nickname = ?,
          phone = ?,
          avatar_url = ?,
          updated_at = NOW()
      WHERE id = ?
    `,
    [fullName, nickname, phone, avatarUrl, userId],
  );

  return getCustomerProfile(userId);
}

async function updateCustomerAvatar(userId, avatarUrl) {
  console.log("DEBUG: updateCustomerAvatar called with userId:", userId, "avatarUrl:", avatarUrl);

  const result = await query(
    `
      UPDATE users
      SET avatar_url = ?,
          updated_at = NOW()
      WHERE id = ?
    `,
    [avatarUrl, userId],
  );

  console.log("DEBUG: UPDATE query result:", result);

  return getCustomerProfile(userId);
}

async function changeCustomerPassword(userId, payload) {
  const currentPassword = normalizeText(payload.currentPassword);
  const newPassword = normalizeText(payload.newPassword);

  if (!currentPassword || !newPassword) {
    throw buildError("Mat khau hien tai va mat khau moi la bat buoc.", 400);
  }

  if (newPassword.length < 8) {
    throw buildError("Mat khau moi phai co it nhat 8 ky tu.", 400);
  }

  const rows = await query(
    `
      SELECT password_hash AS passwordHash
      FROM users
      WHERE id = ?
      LIMIT 1
    `,
    [userId],
  );

  if (rows.length === 0) {
    throw buildError("Khong tim thay nguoi dung.", 404);
  }

  const isValid = await bcrypt.compare(currentPassword, rows[0].passwordHash);
  if (!isValid) {
    throw buildError("Mat khau hien tai khong dung.", 400);
  }

  const passwordHash = await bcrypt.hash(newPassword, 10);
  await query(
    `
      UPDATE users
      SET password_hash = ?,
          updated_at = NOW()
      WHERE id = ?
    `,
    [passwordHash, userId],
  );

  return {
    message: "Cap nhat mat khau thanh cong.",
  };
}

async function getCustomerOrderHistory(userId) {
  return query(
    `
      SELECT
        o.id,
        o.group_order_id AS groupOrderId,
        o.dish_id AS dishId,
        d.name AS dishName,
        c.name AS canteenName,
        o.quantity,
        o.line_total AS lineTotal,
        o.status,
        o.delivery_point AS deliveryPoint,
        o.delivery_zone AS deliveryZone,
        o.delivery_time_slot AS deliveryTimeSlot,
        o.created_at AS createdAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      INNER JOIN canteens c ON c.id = d.canteen_id
      INNER JOIN users u ON u.id = ?
      WHERE u.phone IS NOT NULL
        AND u.phone <> ''
        AND o.student_phone = u.phone
      ORDER BY o.created_at DESC
      LIMIT 50
    `,
    [userId],
  );
}

async function getSavedVouchers(userId) {
  await ensurePromotionsTableCompatibility();

  return query(
    `
      SELECT
        gd.maGiamGiaDaLuu AS id,
        gd.maGiamGia AS promotionId,
        gd.thoiGianLuu AS savedAt,
        gg.maGianHang AS canteenId,
        gg.maMonAn AS dishId,
        m.tenMonAn AS dishName,
        g.tenGianHang AS canteenName,
        gg.maVoucher AS code,
        gg.tenGiamGia AS title,
        gg.moTa AS description,
        gg.phanTramGiam AS discountPercent,
        gg.thoiGianBatDau AS startsAt,
        gg.thoiGianKetThuc AS endsAt,
        gg.trangThai AS isActive
      FROM giamgia_daluu gd
      INNER JOIN giamgia gg ON gg.maGiamGia = gd.maGiamGia
      INNER JOIN gianhang g ON g.maGianHang = gg.maGianHang
      LEFT JOIN monan m ON m.maMonAn = gg.maMonAn
      WHERE gd.maTaiKhoan = ?
      ORDER BY gd.thoiGianLuu DESC
    `,
    [userId],
  );
}

async function saveVoucher(userId, promotionIdInput) {
  await ensurePromotionsTableCompatibility();
  const promotionId = Number(promotionIdInput);

  if (!Number.isInteger(promotionId) || promotionId <= 0) {
    throw buildError("Voucher khong hop le.", 400);
  }

  const promotions = await query(
    `
      SELECT maGiamGia
      FROM giamgia
      WHERE maGiamGia = ?
        AND trangThai = TRUE
        AND (thoiGianBatDau IS NULL OR thoiGianBatDau <= NOW())
        AND (thoiGianKetThuc IS NULL OR thoiGianKetThuc >= NOW())
      LIMIT 1
    `,
    [promotionId],
  );

  if (promotions.length === 0) {
    throw buildError("Voucher khong ton tai hoac da het han su dung.", 404);
  }

  await query(
    `
      INSERT INTO giamgia_daluu (maTaiKhoan, maGiamGia)
      VALUES (?, ?)
      ON DUPLICATE KEY UPDATE thoiGianLuu = CURRENT_TIMESTAMP
    `,
    [userId, promotionId],
  );

  return getSavedVouchers(userId);
}

async function removeSavedVoucher(userId, promotionIdInput) {
  const promotionId = Number(promotionIdInput);

  if (!Number.isInteger(promotionId) || promotionId <= 0) {
    throw buildError("Voucher khong hop le.", 400);
  }

  await query(
    `
      DELETE FROM giamgia_daluu
      WHERE maTaiKhoan = ?
        AND maGiamGia = ?
    `,
    [userId, promotionId],
  );

  return getSavedVouchers(userId);
}

async function getCustomerAccountOverview(userId) {
  const profile = await getCustomerProfile(userId);
  const orders = await getCustomerOrderHistory(userId);
  const vouchers = await getSavedVouchers(userId);
  const totalOrders = orders.length;
  const loyaltyTier = calculateCustomerTier(totalOrders);

  return {
    profile,
    stats: {
      totalOrders,
      totalSpent: orders.reduce((sum, item) => sum + Number(item.lineTotal || 0), 0),
      loyaltyTier,
    },
    orderHistory: orders,
    savedVouchers: vouchers,
  };
}

async function ensureCart(connection, userId) {
  const [insertResult] = await connection.execute(
    `
      INSERT INTO carts (user_id)
      VALUES (?)
      ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id)
    `,
    [userId],
  );

  return insertResult.insertId;
}

async function loadCart(connection, cartId) {
  const [items] = await connection.execute(
    `
      SELECT
        ci.id,
        ci.dish_id AS dishId,
        d.name AS dishName,
        d.price,
        d.image_url AS imageUrl,
        d.canteen_id AS canteenId,
        c.name AS canteenName,
        ci.quantity,
        ci.note,
        (d.price * ci.quantity) AS lineTotal
      FROM cart_items ci
      INNER JOIN dishes d ON d.id = ci.dish_id
      INNER JOIN canteens c ON c.id = d.canteen_id
      WHERE ci.cart_id = ?
      ORDER BY ci.updated_at DESC
    `,
    [cartId],
  );

  const totalAmount = items.reduce((sum, item) => sum + Number(item.lineTotal), 0);
  const totalItems = items.reduce((sum, item) => sum + Number(item.quantity), 0);

  return {
    cartId,
    totalItems,
    totalAmount,
    items,
  };
}

async function getCart(userId) {
  return withTransaction(async (connection) => {
    const cartId = await ensureCart(connection, userId);
    return loadCart(connection, cartId);
  });
}

async function upsertCartItem(userId, payload) {
  const dishId = Number(payload.dishId);
  const quantity = Number(payload.quantity);
  const note = normalizeOptionalText(payload.note);
  const shouldIncrement = payload.increment === true;

  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  if (!Number.isInteger(quantity) || quantity < 0) {
    throw buildError("So luong phai la so nguyen khong am.", 400);
  }

  if (shouldIncrement && quantity <= 0) {
    throw buildError("So luong cong them phai lon hon 0.", 400);
  }

  return withTransaction(async (connection) => {
    const [dishRows] = await connection.execute(
      `
        SELECT id, is_available AS isAvailable
        FROM dishes
        WHERE id = ?
        LIMIT 1
      `,
      [dishId],
    );

    if (dishRows.length === 0) {
      throw buildError("Khong tim thay mon an.", 404);
    }

    if (!dishRows[0].isAvailable) {
      throw buildError("Mon an hien dang tam ngung ban.", 400);
    }

    const cartId = await ensureCart(connection, userId);

    if (!shouldIncrement && quantity === 0) {
      await connection.execute(
        `
          DELETE FROM cart_items
          WHERE cart_id = ? AND dish_id = ?
        `,
        [cartId, dishId],
      );

      return loadCart(connection, cartId);
    }

    if (shouldIncrement) {
      await connection.execute(
        `
          INSERT INTO cart_items (cart_id, dish_id, quantity, note)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            quantity = quantity + VALUES(quantity),
            note = IFNULL(VALUES(note), note),
            updated_at = CURRENT_TIMESTAMP
        `,
        [cartId, dishId, quantity, note],
      );
    } else {
      await connection.execute(
        `
          INSERT INTO cart_items (cart_id, dish_id, quantity, note)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            quantity = VALUES(quantity),
            note = VALUES(note),
            updated_at = CURRENT_TIMESTAMP
        `,
        [cartId, dishId, quantity, note],
      );
    }

    return loadCart(connection, cartId);
  });
}

async function removeCartItem(userId, dishIdInput) {
  const dishId = Number(dishIdInput);

  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.", 400);
  }

  return withTransaction(async (connection) => {
    const cartId = await ensureCart(connection, userId);

    await connection.execute(
      `
        DELETE FROM cart_items
        WHERE cart_id = ?
          AND dish_id = ?
      `,
      [cartId, dishId],
    );

    return loadCart(connection, cartId);
  });
}

module.exports = {
  searchProducts,
  searchCanteens,
  getProductDetail,
  getCanteenDetail,
  getCustomerProfile,
  updateCustomerProfile,
  updateCustomerAvatar,
  changeCustomerPassword,
  getCustomerAccountOverview,
  getSavedVouchers,
  saveVoucher,
  removeSavedVoucher,
  getCart,
  upsertCartItem,
  removeCartItem,
};
