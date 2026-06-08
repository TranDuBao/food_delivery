const express = require('express');
const router = express.Router();
const GroupController = require('../controllers/groupController');
const { verifyToken } = require('../middleware/authMiddleware');

router.use(verifyToken);
router.post('/create', GroupController.createGroup);
router.post('/my-groups', GroupController.getGroups);
router.post('/join', GroupController.joinGroup);
router.post('/leave', GroupController.leaveGroup);
router.post('/remove-member', GroupController.removeMember);
router.post('/disband', GroupController.disbandGroup);

// ── Group Cart ──────────────────────────────────────────────────────────────
router.post('/cart', GroupController.getGroupCart);
router.post('/cart/add', GroupController.addToGroupCart);
router.post('/cart/update', GroupController.updateGroupCartItem);
router.post('/cart/remove', GroupController.removeGroupCartItem);
router.post('/cart/clear', GroupController.clearGroupCart);
router.post('/checkout', GroupController.groupCheckout);

module.exports = router;
