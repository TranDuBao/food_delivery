const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const { query } = require("../config/db");

const DEFAULT_JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "24h";
const DEFAULT_SESSION_TTL_HOURS = Number(process.env.SESSION_TTL_HOURS || 24);
const FALLBACK_JWT_SECRET = "dev-jwt-secret-change-me";
let hasWarnedMissingJwtSecret = false;
const PASSWORD_RESET_TTL_MINUTES = Number(process.env.PASSWORD_RESET_TTL_MINUTES || 30);

function buildError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function normalizePassword(password) {
  return String(password || "").trim();
}

function normalizeFullName(fullName) {
  return String(fullName || "").trim();
}

function normalizeCanteenName(canteenName) {
  return String(canteenName || "").trim();
}

function normalizeRole(role) {
  const value = String(role || "customer").trim().toLowerCase();
  return value === "canteen_staff" ? "canteen_staff" : "customer";
}

function normalizePhone(phone) {
  const raw = String(phone || "").trim().replaceAll(" ", "");
  if (!raw) {
    return null;
  }

  if (!/^\+?[0-9]{9,15}$/.test(raw)) {
    throw buildError("So dien thoai khong hop le.", 400);
  }

  return raw;
}

function normalizeAvatarUrl(avatarUrl) {
  const value = String(avatarUrl || "").trim();
  return value || null;
}

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;

  if (!secret || !secret.trim()) {
    if (!hasWarnedMissingJwtSecret) {
      console.warn("JWT_SECRET is not configured. Using development fallback secret.");
      hasWarnedMissingJwtSecret = true;
    }
    return FALLBACK_JWT_SECRET;
  }

  return secret;
}

async function findActiveUserByEmail(email) {
  const rows = await query(
    `
      SELECT
        id,
        full_name AS fullName,
        email,
        password_hash AS passwordHash,
        role,
        phone,
        avatar_url AS avatarUrl,
        canteen_id AS canteenId,
        is_active AS isActive
      FROM users
      WHERE email = ?
      LIMIT 1
    `,
    [email],
  );

  if (rows.length === 0) {
    return null;
  }

  const user = rows[0];
  if (!user.isActive) {
    return null;
  }

  return user;
}

async function createSession(user, metadata = {}) {
  const tokenJti = crypto.randomUUID();
  const sessionTtlHours = Number.isFinite(DEFAULT_SESSION_TTL_HOURS)
    ? DEFAULT_SESSION_TTL_HOURS
    : 24;

  await query(
    `
      INSERT INTO auth_sessions (
        user_id,
        token_jti,
        user_agent,
        ip_address,
        expires_at
      )
      VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))
    `,
    [
      user.id,
      tokenJti,
      metadata.userAgent || null,
      metadata.ipAddress || null,
      sessionTtlHours,
    ],
  );

  const token = jwt.sign(
    {
      sub: String(user.id),
      sid: tokenJti,
      email: user.email,
      role: user.role,
      canteenId: user.canteenId || null,
    },
    getJwtSecret(),
    { expiresIn: DEFAULT_JWT_EXPIRES_IN },
  );

  return {
    token,
    tokenType: "Bearer",
    expiresIn: DEFAULT_JWT_EXPIRES_IN,
    sessionId: tokenJti,
  };
}

async function login(emailInput, passwordInput, metadata = {}) {
  const email = normalizeEmail(emailInput);
  const password = normalizePassword(passwordInput);

  if (!email || !password) {
    throw buildError("Email va mat khau la bat buoc.", 400);
  }

  const user = await findActiveUserByEmail(email);
  if (!user) {
    throw buildError("Thong tin dang nhap khong hop le.", 401);
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    throw buildError("Thong tin dang nhap khong hop le.", 401);
  }

  await query(
    `
      UPDATE users
      SET last_login_at = NOW(),
          updated_at = NOW()
      WHERE id = ?
    `,
    [user.id],
  );

  const session = await createSession(user, metadata);

  return {
    user: {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      canteenId: user.canteenId,
    },
    session,
  };
}

async function registerAccount(
  fullNameInput,
  emailInput,
  passwordInput,
  mobileInput,
  avatarUrlInput,
  roleInput,
  canteenIdInput,
  canteenNameInput,
  metadata = {},
) {
  const fullName = normalizeFullName(fullNameInput);
  const email = normalizeEmail(emailInput);
  const password = normalizePassword(passwordInput);
  const phone = normalizePhone(mobileInput);
  const avatarUrl = normalizeAvatarUrl(avatarUrlInput);
  const role = normalizeRole(roleInput);
  let canteenId = canteenIdInput ? Number(canteenIdInput) : null;
  const canteenName = normalizeCanteenName(canteenNameInput);

  if (!fullName || !email || !password) {
    throw buildError("Ho ten, email va mat khau la bat buoc.", 400);
  }

  if (password.length < 8) {
    throw buildError("Mat khau phai co it nhat 8 ky tu.", 400);
  }

  if (role === "canteen_staff") {
    if (!Number.isInteger(canteenId) || canteenId <= 0) {
      if (!canteenName) {
        throw buildError("Nhan vien can tin phai chon canteenId hoac nhap ten quan.", 400);
      }

      const existingByName = await query(
        `
          SELECT id
          FROM canteens
          WHERE LOWER(name) = LOWER(?)
          LIMIT 1
        `,
        [canteenName],
      );

      if (existingByName.length > 0) {
        canteenId = Number(existingByName[0].id);
      } else {
        const created = await query(
          `
            INSERT INTO canteens (name, location, open_hours, description)
            VALUES (?, 'Cap nhat sau', '00:00 - 23:59', 'Quan moi dang cap nhat thong tin.')
          `,
          [canteenName],
        );
        canteenId = Number(created.insertId);
      }
    } else {
      const canteenRows = await query(
        `
          SELECT id
          FROM canteens
          WHERE id = ?
          LIMIT 1
        `,
        [canteenId],
      );

      if (canteenRows.length === 0) {
        throw buildError("Khong tim thay gian hang can tin.", 404);
      }
    }
  }

  const existing = await query(
    `
      SELECT id
      FROM users
      WHERE email = ?
      LIMIT 1
    `,
    [email],
  );

  if (existing.length > 0) {
    throw buildError("Email da duoc su dung.", 409);
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const insertResult = await query(
    `
      INSERT INTO users (full_name, email, password_hash, role, phone, avatar_url, canteen_id, is_active)
      VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)
    `,
    [
      fullName,
      email,
      passwordHash,
      role,
      phone,
      avatarUrl,
      role === "canteen_staff" ? canteenId : null,
    ],
  );

  const user = {
    id: insertResult.insertId,
    fullName,
    email,
    role,
    phone,
    avatarUrl,
    canteenId: role === "canteen_staff" ? canteenId : null,
  };

  const session = await createSession(user, metadata);

  return {
    user,
    session,
  };
}

async function forgotPassword(emailInput) {
  const email = normalizeEmail(emailInput);

  if (!email) {
    throw buildError("Email la bat buoc.", 400);
  }

  const user = await findActiveUserByEmail(email);

  if (!user) {
    return {
      message: "Neu email ton tai, huong dan dat lai mat khau da duoc gui.",
    };
  }

  const resetToken = crypto.randomBytes(32).toString("hex");

  await query(
    `
      INSERT INTO password_reset_tokens (user_id, reset_token, expires_at)
      VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))
    `,
    [user.id, resetToken, PASSWORD_RESET_TTL_MINUTES],
  );

  return {
    message: "Tao yeu cau dat lai mat khau thanh cong.",
    resetToken,
    expiresInMinutes: PASSWORD_RESET_TTL_MINUTES,
  };
}

async function resetPassword(resetTokenInput, newPasswordInput) {
  const resetToken = String(resetTokenInput || "").trim();
  const newPassword = normalizePassword(newPasswordInput);

  if (!resetToken || !newPassword) {
    throw buildError("Token va mat khau moi la bat buoc.", 400);
  }

  if (newPassword.length < 8) {
    throw buildError("Mat khau moi phai co it nhat 8 ky tu.", 400);
  }

  const rows = await query(
    `
      SELECT
        id,
        user_id AS userId,
        expires_at AS expiresAt,
        used_at AS usedAt
      FROM password_reset_tokens
      WHERE reset_token = ?
      LIMIT 1
    `,
    [resetToken],
  );

  if (rows.length === 0) {
    throw buildError("Token dat lai mat khau khong hop le.", 400);
  }

  const tokenRow = rows[0];
  const isExpired = new Date(tokenRow.expiresAt).getTime() <= Date.now();

  if (tokenRow.usedAt || isExpired) {
    throw buildError("Token dat lai mat khau da het han hoac da su dung.", 400);
  }

  const passwordHash = await bcrypt.hash(newPassword, 10);

  await query(
    `
      UPDATE users
      SET password_hash = ?,
          updated_at = NOW()
      WHERE id = ?
    `,
    [passwordHash, tokenRow.userId],
  );

  await query(
    `
      UPDATE password_reset_tokens
      SET used_at = NOW()
      WHERE id = ?
    `,
    [tokenRow.id],
  );

  await query(
    `
      UPDATE auth_sessions
      SET is_revoked = TRUE,
          revoked_at = NOW()
      WHERE user_id = ?
        AND is_revoked = FALSE
    `,
    [tokenRow.userId],
  );

  return {
    message: "Cap nhat mat khau thanh cong. Vui long dang nhap lai.",
  };
}

async function validateSession(userId, tokenJti) {
  const rows = await query(
    `
      SELECT
        s.id,
        s.user_id AS userId,
        s.token_jti AS tokenJti,
        s.expires_at AS expiresAt,
        s.is_revoked AS isRevoked,
        u.full_name AS fullName,
        u.email,
        u.role,
        u.phone,
        u.avatar_url AS avatarUrl,
        u.canteen_id AS canteenId,
        u.is_active AS isActive
      FROM auth_sessions s
      INNER JOIN users u ON u.id = s.user_id
      WHERE s.user_id = ?
        AND s.token_jti = ?
      LIMIT 1
    `,
    [userId, tokenJti],
  );

  if (rows.length === 0) {
    return null;
  }

  const session = rows[0];
  const isExpired = new Date(session.expiresAt).getTime() <= Date.now();

  if (!session.isActive || session.isRevoked || isExpired) {
    return null;
  }

  return session;
}

async function touchSession(tokenJti) {
  await query(
    `
      UPDATE auth_sessions
      SET last_used_at = NOW()
      WHERE token_jti = ?
    `,
    [tokenJti],
  );
}

async function revokeSession(userId, tokenJti) {
  const result = await query(
    `
      UPDATE auth_sessions
      SET is_revoked = TRUE,
          revoked_at = NOW()
      WHERE user_id = ?
        AND token_jti = ?
        AND is_revoked = FALSE
    `,
    [userId, tokenJti],
  );

  return result.affectedRows > 0;
}

function verifyAccessToken(token) {
  try {
    return jwt.verify(token, getJwtSecret());
  } catch (error) {
    throw buildError("Token khong hop le hoac da het han.", 401);
  }
}

module.exports = {
  login,
  registerAccount,
  forgotPassword,
  resetPassword,
  validateSession,
  touchSession,
  revokeSession,
  verifyAccessToken,
};
