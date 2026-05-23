const CategoryModel = require('../models/categoryModel');

const CategoryController = {
    getAllCategories: async (req, res, next) => {
        try {
            const categories = await CategoryModel.getAll();
            
            const mapped = categories.map(c => ({
                categoryId: c.maDanhMuc,
                categoryName: c.tenDanhMuc
            }));

            res.status(200).json({ success: true, data: mapped });
        } catch (error) { next(error); }
    }
};

module.exports = CategoryController;
