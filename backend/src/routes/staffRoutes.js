// const express = require("express");

// const {
//   getCategories,
//   addCategory,
//   editCategory,
//   removeCategory,
//   getMenu,
//   addDish,
//   editDish,
//   removeDish,
//   getCanteen,
//   updateCanteen,
//   getPromotions,
//   addPromotion,
//   editPromotion,
//   removePromotion,
//   getOrders,
//   editOrderStatus,
//   getDishOrderStats,
//   uploadDishImage,
// } = require("../controllers/staffController");
// const { requireAuth, requireRoles } = require("../middleware/authMiddleware");
// const { handleDishImageUpload } = require("../config/upload");

// const router = express.Router();

// router.use(requireAuth);
// router.use(requireRoles("canteen_staff"));

// router.get("/categories", getCategories);
// router.post("/categories", addCategory);
// router.put("/categories/:categoryId", editCategory);
// router.delete("/categories/:categoryId", removeCategory);

// router.get("/menu", getMenu);
// router.post("/menu", addDish);
// router.put("/menu/:dishId", editDish);
// router.delete("/menu/:dishId", removeDish);
// router.post("/menu/upload-image", handleDishImageUpload, uploadDishImage);
// router.post("/menu/:dishId/image", handleDishImageUpload, uploadDishImage);

// router.get("/canteen", getCanteen);
// router.put("/canteen", updateCanteen);

// router.get("/orders", getOrders);
// router.put("/orders/:orderId/status", editOrderStatus);
// router.get("/order-stats", getDishOrderStats);

// router.get("/promotions", getPromotions);
// router.post("/promotions", addPromotion);
// router.put("/promotions/:promotionId", editPromotion);
// router.delete("/promotions/:promotionId", removePromotion);

// module.exports = router;
