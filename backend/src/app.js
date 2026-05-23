const express = require("express");
const cors = require("cors");
const path = require("path");

const canteenRoutes = require("./routes/canteenRoutes");
const orderRoutes = require("./routes/orderRoutes");
const authRoutes = require("./routes/authRoutes");
const customerRoutes = require("./routes/customerRoutes");
const shipperRoutes = require("./routes/shipperRoutes");
const errorHandler = require("./middleware/errorHandler");
const dishesRoutes = require("./routes/dishesRoutes");
const cartRoutes = require("./routes/cartRoutes");
const categoryRoutes = require("./routes/categoryRoutes");
const reviewRoutes = require("./routes/reviewRoutes");
const addressRoutes = require("./routes/addressRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const promotionRoutes = require("./routes/promotionRoutes");
const adminRoutes = require("./routes/adminRoutes");
const groupRoutes = require("./routes/groupRoutes");
const dineInRoutes = require("./routes/dineInRoutes");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/img", express.static(path.resolve(__dirname, "../img")));
app.use("/uploads", express.static(path.resolve(__dirname, "../uploads")));
app.use("/public", express.static(path.resolve(__dirname, "../public")));

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    service: "canteen-delivery-backend",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/canteens", canteenRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/customer", customerRoutes);
app.use("/api/shipper", shipperRoutes);
app.use('/api/mon-an', dishesRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/address', addressRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/dine-in', dineInRoutes);

app.use(errorHandler);

module.exports = app;
