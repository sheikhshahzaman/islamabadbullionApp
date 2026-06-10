<?php
// metal/api/latest.php

require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../lib/price_service.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: public, max-age=' . RATES_TTL . ', stale-while-revalidate=60');

$currency = strtoupper(trim($_GET['currency'] ?? ''));

if ($currency === '' || !in_array($currency, APP_CURRENCIES, true)) {
  // Fall back to default currency from settings
  $res = $conn->query("SELECT v FROM settings WHERE k='default_currency' LIMIT 1");
  $row = $res ? $res->fetch_assoc() : null;

  $currency = ($row && !empty($row['v']) && in_array($row['v'], APP_CURRENCIES, true))
    ? strtoupper($row['v'])
    : 'PKR';
}

$response = build_response($currency);

echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
exit;