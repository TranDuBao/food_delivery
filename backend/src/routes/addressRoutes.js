const express = require('express');
const router = express.Router();
const addressController = require('../controllers/addressController');

// Lấy danh sách tòa nhà và phòng học
router.get('/', addressController.getAllAddresses);

module.exports = router;
