const multer = require("multer");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");
const sharp = require("sharp");

const uploadDir = path.resolve(__dirname, "../../img");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

function buildAvatarFilename() {
  return `avatar-${Date.now()}-${crypto.randomUUID()}.jpg`;
}

async function saveCroppedAvatar(buffer) {
  const filename = buildAvatarFilename();
  const fullPath = path.join(uploadDir, filename);

  // Fit cover => auto center crop to square for consistent avatar display.
  await sharp(buffer)
    .rotate()
    .resize(512, 512, { fit: "cover", position: "center" })
    .jpeg({ quality: 85, mozjpeg: true })
    .toFile(fullPath);

  return {
    filename,
    publicPath: `/img/${filename}`,
  };
}

async function saveCroppedDishImage(buffer) {
  const filename = `dish-${Date.now()}-${crypto.randomUUID()}.jpg`;
  const fullPath = path.join(uploadDir, filename);

  await sharp(buffer)
    .rotate()
    .resize(1000, 1000, { fit: "inside", withoutEnlargement: true })
    .jpeg({ quality: 86, mozjpeg: true })
    .toFile(fullPath);

  return {
    filename,
    publicPath: `/img/${filename}`,
  };
}

function fileFilter(_req, file, cb) {
  if (!file.mimetype.startsWith("image/")) {
    const error = new Error("Chi chap nhan tep anh.");
    error.statusCode = 400;
    cb(error);
    return;
  }
  cb(null, true);
}

const avatarUpload = multer({
  storage: multer.memoryStorage(),
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
});

function createUploadHandler(fieldName) {
  return (req, res, next) => {
    avatarUpload.single(fieldName)(req, res, (error) => {
      if (!error) {
        next();
        return;
      }

      if (error.name === "MulterError") {
        const mapped = new Error(
          error.code === "LIMIT_FILE_SIZE"
            ? "Anh vuot qua dung luong 5MB."
            : "Upload anh that bai.",
        );
        mapped.statusCode = 400;
        next(mapped);
        return;
      }

      if (!error.statusCode) {
        error.statusCode = 400;
      }

      next(error);
    });
  };
}

const handleAvatarUpload = createUploadHandler("avatar");
const handleDishImageUpload = createUploadHandler("image");

module.exports = {
  avatarUpload,
  handleAvatarUpload,
  handleDishImageUpload,
  saveCroppedAvatar,
  saveCroppedDishImage,
};
