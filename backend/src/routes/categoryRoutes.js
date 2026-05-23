const express = require('express');
const router = express.Router();
const CategoryController = require('../controllers/categoryController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/', verifyToken, CategoryController.getAllCategories);

module.exports = router;
