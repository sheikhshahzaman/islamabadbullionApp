<?php
// metal/admin/logout.php
require_once __DIR__ . '/../includes/auth.php';
adminLogout();
header('Location: /metal/admin/login.php');
exit;
