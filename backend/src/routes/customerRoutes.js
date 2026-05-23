const express = require('express');
const router = express.Router();
const UserController = require('../controllers/customerController');
const { verifyToken } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

router.get('/me',               verifyToken, UserController.getProfile);
router.put('/me',               verifyToken, UserController.updateProfile);
router.post('/profile/avatar',  verifyToken, upload.single('avatar'), UserController.uploadAvatar);
router.get('/stats',            verifyToken, UserController.getMyStats);

// ── Ví cá nhân ──────────────────────────────────────────────────────────────
router.get('/wallet',           verifyToken, UserController.getWallet);
router.post('/wallet/deposit',  verifyToken, UserController.depositWallet);
router.post('/wallet/withdraw', verifyToken, UserController.withdrawWallet);

module.exports = router;