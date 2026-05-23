const db = require('../config/db');

const CategoryModel = {
    getAll: async () => {
        const rows = await db.query('SELECT * FROM danhmuc');
        return rows;
    }
};

module.exports = CategoryModel;
