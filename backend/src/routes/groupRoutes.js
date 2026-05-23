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

module.exports = router;
