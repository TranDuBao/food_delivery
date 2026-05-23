const { query, withTransaction } = require("../config/db");
const {
  emitRadarOrderUpsert,
  emitRadarOrderRemoved,
  emitGroupCreated,
} = require("../realtime/radarGateway");

const GROUP_RADIUS_METERS = Number(process.env.GROUP_ORDER_RADIUS_METERS || 30);
const MIN_GROUP_SIZE = Number(process.env.GROUP_ORDER_MIN_SIZE || 2);
const WAIT_TIMEOUT_MINUTES = Number(process.env.GROUP_ORDER_WAIT_MINUTES || 5);
const WORKER_INTERVAL_MS = Number(process.env.GROUP_ORDER_WORKER_INTERVAL_MS || 60000);
const FAIL_POLICY = String(process.env.GROUP_ORDER_FAIL_POLICY || "CANCEL_REFUND")
  .trim()
  .toUpperCase();
const SINGLE_ORDER_SURCHARGE = Number(process.env.GROUP_ORDER_SINGLE_SURCHARGE || 8000);
const MATCH_RADIUS_METERS = 30;

let schemaReady = false;
let schemaPromise = null;
let workerTimer = null;

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

function normalizeBuildingCode(value) {
  return normalizeText(value).toLowerCase();
}

function toFiniteNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function toRadians(value) {
  return (value * Math.PI) / 180;
}

function haversineMeters(lat1, lng1, lat2, lng2) {
  const earthRadiusMeters = 6371000;
  const deltaLat = toRadians(lat2 - lat1);
  const deltaLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(deltaLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

function mapOrderRow(row) {
  return {
    id: Number(row.id),
    canteenId: Number(row.canteenId),
    dishId: Number(row.dishId),
    dishName: row.dishName,
    quantity: Number(row.quantity),
    lineTotal: Number(row.lineTotal),
    studentName: row.studentName,
    studentPhone: row.studentPhone,
    deliveryPoint: row.deliveryPoint,
    buildingCode: row.buildingCode,
    floor: row.floor,
    lat: Number(row.lat),
    lng: Number(row.lng),
    status: row.status,
    expiresAt: row.expiresAt,
    createdAt: row.createdAt,
    userId: row.userId ? Number(row.userId) : null,
  };
}

async function ensureRealtimeGroupingSchema() {
  if (schemaReady) {
    return;
  }

  if (schemaPromise) {
    await schemaPromise;
    return;
  }

  schemaPromise = (async () => {
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS user_id INT NULL AFTER id",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS canteen_id INT NULL AFTER user_id",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS lat DECIMAL(10, 7) NULL AFTER delivery_time_slot",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS lng DECIMAL(10, 7) NULL AFTER lat",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS building_code VARCHAR(80) NULL AFTER lng",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS floor VARCHAR(20) NULL AFTER building_code",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS expires_at DATETIME NULL AFTER floor",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS delivery_surcharge DECIMAL(10, 2) NOT NULL DEFAULT 0 AFTER line_total",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS cancellation_reason VARCHAR(120) NULL AFTER delivery_surcharge",
    );
    await query(
      "ALTER TABLE order_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
    );

    await query(
      "ALTER TABLE order_requests MODIFY COLUMN group_order_id INT NULL",
    );
    await query(
      "ALTER TABLE order_requests MODIFY COLUMN status ENUM('pending', 'grouped', 'single_accepted', 'confirmed', 'delivered', 'cancelled', 'abort', 'expired') DEFAULT 'pending'",
    );

    await query(
      "ALTER TABLE group_orders ADD COLUMN IF NOT EXISTS building_code VARCHAR(80) NULL AFTER canteen_id",
    );
    await query(
      "ALTER TABLE group_orders ADD COLUMN IF NOT EXISTS floor VARCHAR(20) NULL AFTER building_code",
    );
    await query(
      "ALTER TABLE group_orders ADD COLUMN IF NOT EXISTS centroid_lat DECIMAL(10, 7) NULL AFTER floor",
    );
    await query(
      "ALTER TABLE group_orders ADD COLUMN IF NOT EXISTS centroid_lng DECIMAL(10, 7) NULL AFTER centroid_lat",
    );

    await query(
      `
        CREATE TABLE IF NOT EXISTS canteen_policies (
          canteen_id INT PRIMARY KEY,
          min_group_size INT NOT NULL DEFAULT 3,
          radius_m INT NOT NULL DEFAULT 30,
          wait_timeout_min INT NOT NULL DEFAULT 5,
          fail_policy ENUM('CANCEL_REFUND', 'SINGLE_WITH_SURCHARGE') NOT NULL DEFAULT 'CANCEL_REFUND',
          single_surcharge_amount DECIMAL(10, 2) NOT NULL DEFAULT 8000,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          CONSTRAINT fk_canteen_policies_canteen
            FOREIGN KEY (canteen_id) REFERENCES canteens(id)
            ON DELETE CASCADE
        )
      `,
    );

    await query(
      `
        INSERT INTO canteen_policies (
          canteen_id,
          min_group_size,
          radius_m,
          wait_timeout_min,
          fail_policy,
          single_surcharge_amount
        )
        SELECT id, ?, ?, ?, ?, ?
        FROM canteens
        ON DUPLICATE KEY UPDATE
          min_group_size = VALUES(min_group_size),
          radius_m = VALUES(radius_m),
          wait_timeout_min = VALUES(wait_timeout_min),
          fail_policy = VALUES(fail_policy),
          single_surcharge_amount = VALUES(single_surcharge_amount)
      `,
      [MIN_GROUP_SIZE, GROUP_RADIUS_METERS, WAIT_TIMEOUT_MINUTES, FAIL_POLICY, SINGLE_ORDER_SURCHARGE],
    );

    await query(
      `
        UPDATE order_requests o
        INNER JOIN dishes d ON d.id = o.dish_id
        SET o.canteen_id = d.canteen_id
        WHERE o.canteen_id IS NULL
      `,
    );

    schemaReady = true;
  })()
    .catch((error) => {
      schemaReady = false;
      throw error;
    })
    .finally(() => {
      schemaPromise = null;
    });

  await schemaPromise;
}

async function listOpenGroupOrders() {
  await ensureRealtimeGroupingSchema();

  return query(
    `
      SELECT
        go.id,
        go.canteen_id AS canteenId,
        c.name AS canteenName,
        go.building_code AS buildingCode,
        go.floor,
        go.centroid_lat AS centroidLat,
        go.centroid_lng AS centroidLng,
        go.delivery_zone AS deliveryZone,
        go.delivery_time_slot AS deliveryTimeSlot,
        go.status,
        go.total_items AS totalItems,
        go.total_amount AS totalAmount,
        go.min_items_required AS minItemsRequired,
        go.created_at AS createdAt,
        go.updated_at AS updatedAt
      FROM group_orders go
      INNER JOIN canteens c ON c.id = go.canteen_id
      WHERE go.status IN ('collecting', 'ready')
      ORDER BY go.created_at DESC
      LIMIT 100
    `,
    [],
  );
}

async function listRadarOrders(auth, queryInput) {
  await ensureRealtimeGroupingSchema();

  const floor = normalizeText(queryInput.floor);
  const lat = toFiniteNumber(queryInput.lat);
  const lng = toFiniteNumber(queryInput.lng);

  if (!floor) {
    throw buildError("floor la bat buoc.");
  }
  if (lat === null || lng === null) {
    throw buildError("Vi tri lat/lng khong hop le.");
  }

  const rows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        user_id AS userId,
        lat,
        lng,
        building_code AS buildingCode,
        floor,
        status,
        expires_at AS expiresAt,
        quantity
      FROM order_requests
      WHERE floor = ?
        AND status = 'pending'
        AND expires_at > NOW()
      ORDER BY created_at DESC
      LIMIT 200
    `,
    [floor],
  );

  return rows
    .filter((row) => {
      if (row.lat === null || row.lng === null) {
        return false;
      }

      const distance = haversineMeters(lat, lng, Number(row.lat), Number(row.lng));
      return distance <= MATCH_RADIUS_METERS;
    })
    .map((row) => ({
      id: Number(row.id),
      canteenId: Number(row.canteenId),
      lat: Number(row.lat),
      lng: Number(row.lng),
      buildingCode: row.buildingCode,
      floor: row.floor,
      status: row.status,
      expiresAt: row.expiresAt,
      quantity: Number(row.quantity),
    }));
}

async function listMyActiveOrders(auth) {
  await ensureRealtimeGroupingSchema();

  if (!auth?.userId) {
    throw buildError("Nguoi dung khong hop le.", 401);
  }

  const rows = await query(
    `
      SELECT
        o.id,
        o.group_order_id AS groupOrderId,
        o.canteen_id AS canteenId,
        c.name AS canteenName,
        o.dish_id AS dishId,
        d.name AS dishName,
        o.quantity,
        o.line_total AS lineTotal,
        o.delivery_surcharge AS deliverySurcharge,
        o.delivery_point AS deliveryPoint,
        o.building_code AS buildingCode,
        o.floor,
        o.lat,
        o.lng,
        o.status,
        o.expires_at AS expiresAt,
        o.created_at AS createdAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      INNER JOIN canteens c ON c.id = o.canteen_id
      WHERE o.user_id = ?
        AND o.status IN ('pending', 'grouped', 'single_accepted', 'confirmed')
      ORDER BY o.created_at DESC
      LIMIT 100
    `,
    [Number(auth.userId)],
  );

  return rows.map((row) => ({
    id: Number(row.id),
    groupOrderId: row.groupOrderId ? Number(row.groupOrderId) : null,
    canteenId: Number(row.canteenId),
    canteenName: row.canteenName,
    dishId: Number(row.dishId),
    dishName: row.dishName,
    quantity: Number(row.quantity),
    lineTotal: Number(row.lineTotal),
    deliverySurcharge: Number(row.deliverySurcharge || 0),
    deliveryPoint: row.deliveryPoint,
    buildingCode: row.buildingCode,
    floor: row.floor,
    lat: row.lat === null ? null : Number(row.lat),
    lng: row.lng === null ? null : Number(row.lng),
    status: row.status,
    expiresAt: row.expiresAt,
    createdAt: row.createdAt,
  }));
}

async function listMyOrders(auth, queryInput = {}) {
  await ensureRealtimeGroupingSchema();

  if (!auth?.userId) {
    throw buildError("Nguoi dung khong hop le.", 401);
  }

  const allowedStatuses = new Set([
    "pending",
    "grouped",
    "single_accepted",
    "confirmed",
    "delivered",
    "cancelled",
    "abort",
    "expired",
  ]);

  const requestedStatuses = normalizeText(queryInput.status)
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);

  const invalidStatuses = requestedStatuses.filter((status) => !allowedStatuses.has(status));
  if (invalidStatuses.length > 0) {
    throw buildError("Bo loc trang thai khong hop le.");
  }

  const parsedLimit = Number(queryInput.limit);
  const limit = Number.isInteger(parsedLimit) && parsedLimit > 0
    ? Math.min(parsedLimit, 200)
    : 100;

  const params = [Number(auth.userId)];
  let statusClause = "";

  if (requestedStatuses.length > 0) {
    statusClause = ` AND o.status IN (${requestedStatuses.map(() => "?").join(",")})`;
    params.push(...requestedStatuses);
  }

  params.push(limit);

  const rows = await query(
    `
      SELECT
        o.id,
        o.group_order_id AS groupOrderId,
        o.canteen_id AS canteenId,
        c.name AS canteenName,
        o.dish_id AS dishId,
        d.name AS dishName,
        o.quantity,
        o.note,
        o.line_total AS lineTotal,
        o.delivery_surcharge AS deliverySurcharge,
        o.delivery_point AS deliveryPoint,
        o.delivery_zone AS deliveryZone,
        o.building_code AS buildingCode,
        o.floor,
        o.lat,
        o.lng,
        o.status,
        o.cancellation_reason AS cancellationReason,
        o.expires_at AS expiresAt,
        o.created_at AS createdAt,
        o.updated_at AS updatedAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      INNER JOIN canteens c ON c.id = o.canteen_id
      WHERE o.user_id = ?
      ${statusClause}
      ORDER BY o.created_at DESC
      LIMIT ?
    `,
    params,
  );

  return rows.map((row) => ({
    id: Number(row.id),
    groupOrderId: row.groupOrderId ? Number(row.groupOrderId) : null,
    canteenId: Number(row.canteenId),
    canteenName: row.canteenName,
    dishId: Number(row.dishId),
    dishName: row.dishName,
    quantity: Number(row.quantity),
    note: row.note,
    lineTotal: Number(row.lineTotal),
    deliverySurcharge: Number(row.deliverySurcharge || 0),
    deliveryPoint: row.deliveryPoint,
    deliveryZone: row.deliveryZone,
    buildingCode: row.buildingCode,
    floor: row.floor,
    lat: row.lat === null ? null : Number(row.lat),
    lng: row.lng === null ? null : Number(row.lng),
    status: row.status,
    cancellationReason: row.cancellationReason,
    expiresAt: row.expiresAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  }));
}

async function getMyOrderDetail(auth, orderIdInput) {
  await ensureRealtimeGroupingSchema();

  if (!auth?.userId) {
    throw buildError("Nguoi dung khong hop le.", 401);
  }

  const orderId = Number(orderIdInput);
  if (!Number.isInteger(orderId) || orderId <= 0) {
    throw buildError("Don hang khong hop le.");
  }

  const rows = await query(
    `
      SELECT
        o.id,
        o.group_order_id AS groupOrderId,
        o.user_id AS userId,
        o.canteen_id AS canteenId,
        c.name AS canteenName,
        o.dish_id AS dishId,
        d.name AS dishName,
        o.student_name AS studentName,
        o.student_phone AS studentPhone,
        o.quantity,
        o.note,
        o.line_total AS lineTotal,
        o.delivery_surcharge AS deliverySurcharge,
        o.delivery_point AS deliveryPoint,
        o.delivery_zone AS deliveryZone,
        o.building_code AS buildingCode,
        o.floor,
        o.lat,
        o.lng,
        o.status,
        o.cancellation_reason AS cancellationReason,
        o.expires_at AS expiresAt,
        o.created_at AS createdAt,
        o.updated_at AS updatedAt
      FROM order_requests o
      INNER JOIN dishes d ON d.id = o.dish_id
      INNER JOIN canteens c ON c.id = o.canteen_id
      WHERE o.id = ?
        AND o.user_id = ?
      LIMIT 1
    `,
    [orderId, Number(auth.userId)],
  );

  if (rows.length === 0) {
    throw buildError("Khong tim thay don hang.", 404);
  }

  const row = rows[0];
  return {
    id: Number(row.id),
    groupOrderId: row.groupOrderId ? Number(row.groupOrderId) : null,
    userId: Number(row.userId),
    canteenId: Number(row.canteenId),
    canteenName: row.canteenName,
    dishId: Number(row.dishId),
    dishName: row.dishName,
    studentName: row.studentName,
    studentPhone: row.studentPhone,
    quantity: Number(row.quantity),
    note: row.note,
    lineTotal: Number(row.lineTotal),
    deliverySurcharge: Number(row.deliverySurcharge || 0),
    deliveryPoint: row.deliveryPoint,
    deliveryZone: row.deliveryZone,
    buildingCode: row.buildingCode,
    floor: row.floor,
    lat: row.lat === null ? null : Number(row.lat),
    lng: row.lng === null ? null : Number(row.lng),
    status: row.status,
    cancellationReason: row.cancellationReason,
    expiresAt: row.expiresAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function cancelMyOrder(auth, orderIdInput, payload = {}) {
  await ensureRealtimeGroupingSchema();

  if (!auth?.userId) {
    throw buildError("Nguoi dung khong hop le.", 401);
  }

  const orderId = Number(orderIdInput);
  if (!Number.isInteger(orderId) || orderId <= 0) {
    throw buildError("Don hang khong hop le.");
  }

  const cancellationReason = normalizeOptionalText(payload.reason) || "CUSTOMER_CANCELLED";
  const cancellableStatuses = new Set(["pending"]);

  const txResult = await withTransaction(async (connection) => {
    const [orderRows] = await connection.execute(
      `
        SELECT
          id,
          user_id AS userId,
          group_order_id AS groupOrderId,
          canteen_id AS canteenId,
          building_code AS buildingCode,
          floor,
          status
        FROM order_requests
        WHERE id = ?
          AND user_id = ?
        LIMIT 1
        FOR UPDATE
      `,
      [orderId, Number(auth.userId)],
    );

    if (orderRows.length === 0) {
      throw buildError("Khong tim thay don hang.", 404);
    }

    const currentOrder = orderRows[0];
    const currentStatus = String(currentOrder.status || "").toLowerCase();

    if (!cancellableStatuses.has(currentStatus)) {
      throw buildError("Don hang hien tai khong the huy.", 400);
    }

    await connection.execute(
      `
        UPDATE order_requests
        SET status = 'abort',
            cancellation_reason = ?,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `,
      [cancellationReason, orderId],
    );

    if (currentOrder.groupOrderId) {
      await refreshGroupAggregate(connection, Number(currentOrder.groupOrderId));

      const [activeRows] = await connection.execute(
        `
          SELECT COUNT(*) AS totalActive
          FROM order_requests
          WHERE group_order_id = ?
            AND status IN ('pending', 'grouped', 'single_accepted', 'confirmed')
        `,
        [Number(currentOrder.groupOrderId)],
      );

      if (Number(activeRows[0]?.totalActive || 0) === 0) {
        await connection.execute(
          `
            UPDATE group_orders
            SET status = 'cancelled',
                total_items = 0,
                total_amount = 0,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
          `,
          [Number(currentOrder.groupOrderId)],
        );
      }
    }

    return {
      id: Number(currentOrder.id),
      previousStatus: currentStatus,
      canteenId: Number(currentOrder.canteenId),
      buildingCode: currentOrder.buildingCode,
      floor: currentOrder.floor,
    };
  });

  if (txResult.previousStatus === "pending") {
    emitRadarOrderRemoved({
      id: txResult.id,
      canteenId: txResult.canteenId,
      buildingCode: txResult.buildingCode,
      floor: txResult.floor,
      status: "abort",
    });
  }

  const order = await getMyOrderDetail(auth, orderId);

  return {
    message: "Da huy don hang.",
    orderRequest: order,
  };
}

async function findCollectingGroupForFloor(connection, { floor, lat, lng }) {
  const [rows] = await connection.execute(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        floor,
        centroid_lat AS centroidLat,
        centroid_lng AS centroidLng,
        created_at AS createdAt
      FROM group_orders
      WHERE status = 'collecting'
        AND floor = ?
        AND created_at >= DATE_SUB(NOW(), INTERVAL ? MINUTE)
      FOR UPDATE
    `,
    [floor, WAIT_TIMEOUT_MINUTES],
  );

  let matched = null;
  let minDistance = Number.POSITIVE_INFINITY;

  for (const row of rows) {
    if (row.centroidLat === null || row.centroidLng === null) {
      continue;
    }
    const distance = haversineMeters(
      lat,
      lng,
      Number(row.centroidLat),
      Number(row.centroidLng),
    );
    if (distance <= MATCH_RADIUS_METERS && distance < minDistance) {
      matched = row;
      minDistance = distance;
    }
  }

  return matched;
}

async function refreshGroupAggregate(connection, groupId) {
  await connection.execute(
    `
      UPDATE group_orders g
      JOIN (
        SELECT
          group_order_id AS groupId,
          COALESCE(SUM(quantity), 0) AS totalItems,
          COALESCE(SUM(line_total), 0) AS totalAmount,
          AVG(lat) AS centroidLat,
          AVG(lng) AS centroidLng
        FROM order_requests
        WHERE group_order_id = ?
          AND status IN ('pending', 'grouped')
        GROUP BY group_order_id
      ) s ON s.groupId = g.id
      SET g.total_items = s.totalItems,
          g.total_amount = s.totalAmount,
          g.centroid_lat = s.centroidLat,
          g.centroid_lng = s.centroidLng,
          g.updated_at = CURRENT_TIMESTAMP
      WHERE g.id = ?
    `,
    [groupId, groupId],
  );
}

async function createOrderRequest(auth, payload) {
  await ensureRealtimeGroupingSchema();

  const studentName = normalizeText(payload.studentName) || normalizeText(auth?.fullName);
  const studentPhone =
    normalizeText(payload.studentPhone) || normalizeText(auth?.phone) || "N/A";
  const deliveryPoint = normalizeText(payload.deliveryPoint) || 'Sanh toa A';
  const buildingCode = normalizeBuildingCode(payload.buildingCode) || 'a';
  const floor = normalizeText(payload.floor);
  const note = normalizeText(payload.note);
  const lat = toFiniteNumber(payload.lat);
  const lng = toFiniteNumber(payload.lng);
  const dishId = Number(payload.dishId);
  const quantity = Number(payload.quantity);
  const canteenId = Number(payload.canteenId);

  if (!studentName || !floor) {
    throw buildError("Vui long nhap day du thong tin dat hang va vi tri tang.");
  }
  if (lat === null || lng === null) {
    throw buildError("Toa do lat/lng khong hop le.");
  }
  if (!Number.isInteger(dishId) || dishId <= 0) {
    throw buildError("Mon an khong hop le.");
  }
  if (!Number.isInteger(quantity) || quantity <= 0) {
    throw buildError("So luong mon phai lon hon 0.");
  }

  const dishRows = await query(
    `
      SELECT
        d.id,
        d.name,
        d.price,
        d.canteen_id AS canteenId,
        c.name AS canteenName
      FROM dishes d
      INNER JOIN canteens c ON c.id = d.canteen_id
      WHERE d.id = ? AND d.is_available = TRUE
      LIMIT 1
    `,
    [dishId],
  );

  if (dishRows.length === 0) {
    throw buildError("Khong tim thay mon an hoac mon dang tam ngung ban.", 404);
  }

  const dish = dishRows[0];
  if (canteenId && Number(dish.canteenId) !== canteenId) {
    throw buildError("Mon an khong thuoc can tin da chon.");
  }

  const lineTotal = Number(dish.price) * quantity;
  const slot = new Date().toISOString().slice(0, 16).replace("T", " ");
  const zone = `${buildingCode}:${floor}`;

  const txResult = await withTransaction(async (connection) => {
    let group = await findCollectingGroupForFloor(connection, {
      floor,
      lat,
      lng,
    });

    if (!group) {
      const [groupResult] = await connection.execute(
        `
          INSERT INTO group_orders (
            canteen_id,
            building_code,
            floor,
            centroid_lat,
            centroid_lng,
            delivery_zone,
            delivery_time_slot,
            status,
            total_items,
            total_amount,
            min_items_required
          )
          VALUES (?, NULL, ?, ?, ?, ?, DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i'), 'collecting', 0, 0, ?)
        `,
        [dish.canteenId, floor, lat, lng, `floor:${floor}`, MIN_GROUP_SIZE],
      );

      const [newGroupRows] = await connection.execute(
        `
          SELECT
            id,
            canteen_id AS canteenId,
            floor,
            centroid_lat AS centroidLat,
            centroid_lng AS centroidLng,
            created_at AS createdAt
          FROM group_orders
          WHERE id = ?
          LIMIT 1
          FOR UPDATE
        `,
        [groupResult.insertId],
      );
      group = newGroupRows[0];
    }

    const deadline = new Date(new Date(group.createdAt).getTime() + WAIT_TIMEOUT_MINUTES * 60000);

    const [insertOrderResult] = await connection.execute(
      `
        INSERT INTO order_requests (
          user_id,
          canteen_id,
          group_order_id,
          dish_id,
          student_name,
          student_phone,
          quantity,
          note,
          delivery_point,
          delivery_zone,
          delivery_time_slot,
          lat,
          lng,
          building_code,
          floor,
          expires_at,
          line_total,
          delivery_surcharge,
          status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'pending')
      `,
      [
        auth?.userId || null,
        dish.canteenId,
        Number(group.id),
        dish.id,
        studentName,
        studentPhone,
        quantity,
        note || null,
        deliveryPoint,
        zone,
        slot,
        lat,
        lng,
        buildingCode,
        floor,
        deadline,
        lineTotal,
      ],
    );

    await refreshGroupAggregate(connection, Number(group.id));

    const [memberRows] = await connection.execute(
      `
        SELECT
          id,
          user_id AS userId,
          canteen_id AS canteenId,
          building_code AS buildingCode,
          floor
        FROM order_requests
        WHERE group_order_id = ?
          AND status IN ('pending', 'grouped')
      `,
      [Number(group.id)],
    );

    const groupLocked = false;

    const [rows] = await connection.execute(
      `
        SELECT
          o.id,
          o.user_id AS userId,
          o.canteen_id AS canteenId,
          o.dish_id AS dishId,
          d.name AS dishName,
          o.student_name AS studentName,
          o.student_phone AS studentPhone,
          o.quantity,
          o.note,
          o.delivery_point AS deliveryPoint,
          o.building_code AS buildingCode,
          o.floor,
          o.lat,
          o.lng,
          o.line_total AS lineTotal,
          o.status,
          o.expires_at AS expiresAt,
          o.created_at AS createdAt
        FROM order_requests o
        INNER JOIN dishes d ON d.id = o.dish_id
        WHERE o.id = ?
        LIMIT 1
      `,
      [insertOrderResult.insertId],
    );

    const [groupRows] = await connection.execute(
      `
        SELECT
          id AS groupId,
          canteen_id AS canteenId,
          floor,
          centroid_lat AS centroidLat,
          centroid_lng AS centroidLng,
          status,
          total_items AS totalItems,
          total_amount AS totalAmount,
          min_items_required AS minItemsRequired,
          created_at AS createdAt
        FROM group_orders
        WHERE id = ?
        LIMIT 1
      `,
      [Number(group.id)],
    );

    return {
      orderRequest: mapOrderRow(rows[0]),
      group: groupRows[0] || null,
      groupLocked,
      members: memberRows,
    };
  });

  emitRadarOrderUpsert(txResult.orderRequest);

  return {
    message: "Da tao don cho gom nhom theo thoi gian thuc.",
    orderRequest: txResult.orderRequest,
    waitTimeoutMinutes: WAIT_TIMEOUT_MINUTES,
    radiusMeters: MATCH_RADIUS_METERS,
    minGroupSize: MIN_GROUP_SIZE,
    groupLocked: txResult.groupLocked,
  };
}

function buildConnectedComponents(rows, radiusMeters) {
  const adjacency = new Map();
  rows.forEach((row) => {
    adjacency.set(row.id, []);
  });

  for (let i = 0; i < rows.length; i += 1) {
    for (let j = i + 1; j < rows.length; j += 1) {
      const a = rows[i];
      const b = rows[j];

      if (a.lat === null || a.lng === null || b.lat === null || b.lng === null) {
        continue;
      }

      if (haversineMeters(Number(a.lat), Number(a.lng), Number(b.lat), Number(b.lng)) <= radiusMeters) {
        adjacency.get(a.id).push(b.id);
        adjacency.get(b.id).push(a.id);
      }
    }
  }

  const rowMap = new Map(rows.map((row) => [row.id, row]));
  const visited = new Set();
  const components = [];

  rows.forEach((row) => {
    if (visited.has(row.id)) {
      return;
    }

    const stack = [row.id];
    visited.add(row.id);
    const component = [];

    while (stack.length > 0) {
      const node = stack.pop();
      component.push(rowMap.get(node));

      const neighbors = adjacency.get(node) || [];
      neighbors.forEach((neighbor) => {
        if (!visited.has(neighbor)) {
          visited.add(neighbor);
          stack.push(neighbor);
        }
      });
    }

    components.push(component);
  });

  return components;
}

async function getPolicyForCanteen(canteenId) {
  const rows = await query(
    `
      SELECT
        min_group_size AS minGroupSize,
        radius_m AS radiusMeters,
        wait_timeout_min AS waitTimeoutMinutes,
        fail_policy AS failPolicy,
        single_surcharge_amount AS singleSurchargeAmount
      FROM canteen_policies
      WHERE canteen_id = ?
      LIMIT 1
    `,
    [canteenId],
  );

  if (rows.length === 0) {
    return {
      minGroupSize: MIN_GROUP_SIZE,
      radiusMeters: GROUP_RADIUS_METERS,
      waitTimeoutMinutes: WAIT_TIMEOUT_MINUTES,
      failPolicy: FAIL_POLICY,
      singleSurchargeAmount: SINGLE_ORDER_SURCHARGE,
    };
  }

  return {
    minGroupSize: Number(rows[0].minGroupSize) || MIN_GROUP_SIZE,
    radiusMeters: Number(rows[0].radiusMeters) || GROUP_RADIUS_METERS,
    waitTimeoutMinutes: Number(rows[0].waitTimeoutMinutes) || WAIT_TIMEOUT_MINUTES,
    failPolicy: String(rows[0].failPolicy || FAIL_POLICY).toUpperCase(),
    singleSurchargeAmount: Number(rows[0].singleSurchargeAmount) || SINGLE_ORDER_SURCHARGE,
  };
}

async function createGroupFromRows(rows) {
  if (rows.length < MIN_GROUP_SIZE) {
    return null;
  }

  const dominantCanteenId = Number(rows[0]?.canteenId || 0);

  return withTransaction(async (connection) => {
    const ids = rows.map((row) => Number(row.id));
    const placeholders = ids.map(() => "?").join(",");

    const [lockedRows] = await connection.execute(
      `
        SELECT
          id,
          canteen_id AS canteenId,
          quantity,
          line_total AS lineTotal,
          lat,
          lng,
          building_code AS buildingCode,
          floor
        FROM order_requests
        WHERE id IN (${placeholders})
          AND status = 'pending'
          AND expires_at > NOW()
        FOR UPDATE
      `,
      ids,
    );

    if (lockedRows.length < MIN_GROUP_SIZE) {
      return null;
    }

    const first = lockedRows[0];
    const totalItems = lockedRows.reduce((sum, row) => sum + Number(row.quantity || 0), 0);
    const totalAmount = lockedRows.reduce((sum, row) => sum + Number(row.lineTotal || 0), 0);
    const centroidLat =
      lockedRows.reduce((sum, row) => sum + Number(row.lat || 0), 0) / lockedRows.length;
    const centroidLng =
      lockedRows.reduce((sum, row) => sum + Number(row.lng || 0), 0) / lockedRows.length;

    const [groupResult] = await connection.execute(
      `
        INSERT INTO group_orders (
          canteen_id,
          building_code,
          floor,
          centroid_lat,
          centroid_lng,
          delivery_zone,
          delivery_time_slot,
          status,
          total_items,
          total_amount,
          min_items_required
        )
        VALUES (?, ?, ?, ?, ?, ?, DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i'), 'ready', ?, ?, ?)
      `,
      [
        dominantCanteenId,
        null,
        first.floor,
        centroidLat,
        centroidLng,
        `floor:${first.floor}`,
        totalItems,
        totalAmount,
        MIN_GROUP_SIZE,
      ],
    );

    await connection.execute(
      `
        UPDATE order_requests
        SET group_order_id = ?,
            status = 'grouped',
            updated_at = CURRENT_TIMESTAMP
        WHERE id IN (${placeholders})
      `,
      [groupResult.insertId, ...ids],
    );

    return {
      groupId: Number(groupResult.insertId),
      canteenId: Number(first.canteenId),
      buildingCode: first.buildingCode,
      floor: first.floor,
      memberCount: lockedRows.length,
      orderIds: lockedRows.map((row) => Number(row.id)),
      totalItems,
      totalAmount,
      centroidLat,
      centroidLng,
      status: "ready",
      createdAt: new Date().toISOString(),
    };
  });
}

async function processPendingGroups(filter = {}) {
  const params = [];
  const conditions = ["status = 'pending'", "group_order_id IS NULL", "expires_at > NOW()", "lat IS NOT NULL", "lng IS NOT NULL"];

  if (filter.floor) {
    conditions.push("floor = ?");
    params.push(normalizeText(filter.floor));
  }

  const rows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        building_code AS buildingCode,
        floor,
        lat,
        lng,
        quantity,
        line_total AS lineTotal
      FROM order_requests
      WHERE ${conditions.join(" AND ")}
      ORDER BY created_at ASC
      LIMIT 500
    `,
    params,
  );

  const buckets = new Map();
  rows.forEach((row) => {
    const key = `${row.floor}`;
    if (!buckets.has(key)) {
      buckets.set(key, []);
    }
    buckets.get(key).push(row);
  });

  let groupedCount = 0;
  for (const bucketRows of buckets.values()) {
    if (bucketRows.length < MIN_GROUP_SIZE) {
      continue;
    }

    const components = buildConnectedComponents(bucketRows, MATCH_RADIUS_METERS);

    for (const component of components) {
      if (component.length < MIN_GROUP_SIZE) {
        continue;
      }

      const group = await createGroupFromRows(component);
      if (!group) {
        continue;
      }

      groupedCount += group.memberCount;
      component.forEach((order) => {
        emitRadarOrderRemoved({
          id: Number(order.id),
          canteenId: Number(order.canteenId),
          buildingCode: order.buildingCode,
          floor: order.floor,
          status: "grouped",
        });
      });
      emitGroupCreated(group);
    }
  }

  return groupedCount;
}

async function processExpiredPendingOrders(filter = {}) {
  const params = [];
  const conditions = ["status = 'pending'", "group_order_id IS NULL", "expires_at <= NOW()"];

  if (filter.canteenId) {
    conditions.push("canteen_id = ?");
    params.push(Number(filter.canteenId));
  }
  if (filter.buildingCode) {
    conditions.push("building_code = ?");
    params.push(normalizeBuildingCode(filter.buildingCode));
  }
  if (filter.floor) {
    conditions.push("floor = ?");
    params.push(normalizeText(filter.floor));
  }

  const expiredRows = await query(
    `
      SELECT
        id,
        canteen_id AS canteenId,
        building_code AS buildingCode,
        floor
      FROM order_requests
      WHERE ${conditions.join(" AND ")}
      ORDER BY expires_at ASC
      LIMIT 300
    `,
    params,
  );

  let handled = 0;
  for (const order of expiredRows) {
    const policy = await getPolicyForCanteen(Number(order.canteenId));

    const outcome = await withTransaction(async (connection) => {
      const [rows] = await connection.execute(
        `
          SELECT id, status
          FROM order_requests
          WHERE id = ?
          FOR UPDATE
        `,
        [Number(order.id)],
      );

      if (rows.length === 0 || rows[0].status !== "pending") {
        return null;
      }

      if (policy.failPolicy === "SINGLE_WITH_SURCHARGE") {
        await connection.execute(
          `
            UPDATE order_requests
            SET status = 'single_accepted',
                delivery_surcharge = ?,
                cancellation_reason = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
          `,
          [policy.singleSurchargeAmount, Number(order.id)],
        );

        return "single_accepted";
      }

      await connection.execute(
        `
          UPDATE order_requests
          SET status = 'cancelled',
              cancellation_reason = 'GROUP_TIMEOUT_REFUND',
              updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `,
        [Number(order.id)],
      );

      return "cancelled";
    });

    if (!outcome) {
      continue;
    }

    handled += 1;
    emitRadarOrderRemoved({
      id: Number(order.id),
      canteenId: Number(order.canteenId),
      buildingCode: order.buildingCode,
      floor: order.floor,
      status: outcome,
    });
  }

  return handled;
}

async function processCollectingGroupTimeouts(filter = {}) {
  const params = [WAIT_TIMEOUT_MINUTES];
  const conditions = [
    "status = 'collecting'",
    "created_at <= DATE_SUB(NOW(), INTERVAL ? MINUTE)",
  ];

  if (filter.floor) {
    conditions.push("floor = ?");
    params.push(normalizeText(filter.floor));
  }

  const groups = await query(
    `
      SELECT
        id AS groupId
      FROM group_orders
      WHERE ${conditions.join(" AND ")}
      ORDER BY created_at ASC
      LIMIT 100
    `,
    params,
  );

  let closedGroups = 0;
  for (const item of groups) {
    const outcome = await withTransaction(async (connection) => {
      const [groupRows] = await connection.execute(
        `
          SELECT
            id,
            canteen_id AS canteenId,
            floor,
            status,
            created_at AS createdAt
          FROM group_orders
          WHERE id = ?
          FOR UPDATE
        `,
        [Number(item.groupId)],
      );

      if (groupRows.length === 0) {
        return null;
      }

      const group = groupRows[0];
      if (group.status !== "collecting") {
        return null;
      }

      const startedAt = new Date(group.createdAt);
      const closesAt = new Date(startedAt.getTime() + WAIT_TIMEOUT_MINUTES * 60000);
      if (Date.now() < closesAt.getTime()) {
        return null;
      }

      await connection.execute(
        `
          UPDATE order_requests
          SET status = 'grouped',
              updated_at = CURRENT_TIMESTAMP
          WHERE group_order_id = ?
            AND status = 'pending'
        `,
        [Number(group.id)],
      );

      await refreshGroupAggregate(connection, Number(group.id));

      await connection.execute(
        `
          UPDATE group_orders
          SET status = 'ready',
              updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `,
        [Number(group.id)],
      );

      const [memberRows] = await connection.execute(
        `
          SELECT
            id,
            canteen_id AS canteenId,
            building_code AS buildingCode,
            floor
          FROM order_requests
          WHERE group_order_id = ?
        `,
        [Number(group.id)],
      );

      const [readyRows] = await connection.execute(
        `
          SELECT
            id AS groupId,
            canteen_id AS canteenId,
            floor,
            centroid_lat AS centroidLat,
            centroid_lng AS centroidLng,
            status,
            total_items AS totalItems,
            total_amount AS totalAmount,
            min_items_required AS minItemsRequired,
            created_at AS createdAt
          FROM group_orders
          WHERE id = ?
          LIMIT 1
        `,
        [Number(group.id)],
      );

      return {
        members: memberRows,
        group: readyRows[0] || null,
      };
    });

    if (!outcome) {
      continue;
    }

    closedGroups += 1;
    outcome.members.forEach((order) => {
      emitRadarOrderRemoved({
        id: Number(order.id),
        canteenId: Number(order.canteenId),
        buildingCode: order.buildingCode,
        floor: order.floor,
        status: "grouped",
      });
    });
    if (outcome.group) {
      emitGroupCreated(outcome.group);
    }
  }

  return closedGroups;
}

async function runMatchingTick(filter = {}) {
  await ensureRealtimeGroupingSchema();
  // Disable early grouping so orders are only grouped when the collecting window ends.
  const groupedCount = 0;
  const timeoutClosedGroups = await processCollectingGroupTimeouts(filter);
  const expiredHandledCount = await processExpiredPendingOrders(filter);

  return {
    groupedCount,
    timeoutClosedGroups,
    expiredHandledCount,
  };
}

function startMatchingWorker() {
  if (workerTimer) {
    return;
  }

  workerTimer = setInterval(() => {
    runMatchingTick().catch((error) => {
      console.error("Group-order worker tick failed:", error.message);
    });
  }, WORKER_INTERVAL_MS);

  runMatchingTick().catch((error) => {
    console.error("Initial group-order worker tick failed:", error.message);
  });
}

function stopMatchingWorker() {
  if (!workerTimer) {
    return;
  }

  clearInterval(workerTimer);
  workerTimer = null;
}

module.exports = {
  createOrderRequest,
  listOpenGroupOrders,
  listRadarOrders,
  listMyActiveOrders,
  listMyOrders,
  getMyOrderDetail,
  cancelMyOrder,
  runMatchingTick,
  startMatchingWorker,
  stopMatchingWorker,
  ensureRealtimeGroupingSchema,
};
