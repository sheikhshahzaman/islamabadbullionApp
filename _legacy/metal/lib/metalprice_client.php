<?php
// metal/lib/metalprice_client.php
require_once __DIR__ . '/../includes/db.php';

function get_setting_value(string $k, string $fallback = ''): string {
  global $conn;
  $stmt = $conn->prepare("SELECT v FROM settings WHERE k=? LIMIT 1");
  $stmt->bind_param('s', $k);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $stmt->close();
  return $row ? (string)$row['v'] : $fallback;
}

function get_metal_api_key(): string {
  return trim(get_setting_value('api_key', ''));
}

function _load_cache_row(string $currenciesCsv): ?array {
  global $conn;

  $stmt = $conn->prepare("
    SELECT response_json, fetched_at
    FROM rate_cache
    WHERE base='USD' AND currencies=?
    ORDER BY id DESC
    LIMIT 1
  ");
  $stmt->bind_param('s', $currenciesCsv);
  $stmt->execute();
  $res = $stmt->get_result()->fetch_assoc();
  $stmt->close();

  if (!$res) return null;

  $json = json_decode($res['response_json'], true);
  if (!is_array($json)) return null;

  $age = time() - strtotime($res['fetched_at']);

  return [
    'json'       => $json,
    'fetched_at' => $res['fetched_at'],
    'age'        => $age,
  ];
}

function _load_fresh_cache(string $currenciesCsv): ?array {
  $row = _load_cache_row($currenciesCsv);
  if (!$row) return null;

  if ($row['age'] <= RATES_TTL) {
    return $row['json'];
  }

  return null;
}

function _load_stale_cache(string $currenciesCsv): ?array {
  $row = _load_cache_row($currenciesCsv);
  if (!$row) return null;

  if (defined('RATES_STALE_TTL') && $row['age'] <= RATES_STALE_TTL) {
    return $row['json'];
  }

  return null;
}

function _save_cache(string $currenciesCsv, array $json): void {
  global $conn;

  $stmt = $conn->prepare("
    INSERT INTO rate_cache (base, currencies, response_json, fetched_at)
    VALUES ('USD', ?, ?, NOW())
  ");
  $j = json_encode($json);
  $stmt->bind_param('ss', $currenciesCsv, $j);
  $stmt->execute();
  $stmt->close();

  // Optional cleanup to stop table growth
  $stmt = $conn->prepare("
    DELETE FROM rate_cache
    WHERE base='USD'
      AND currencies=?
      AND fetched_at < (NOW() - INTERVAL 7 DAY)
  ");
  $stmt->bind_param('s', $currenciesCsv);
  $stmt->execute();
  $stmt->close();
}

function _lock_name(string $currenciesCsv): string {
  return 'metal_rates_' . md5($currenciesCsv);
}

function _acquire_refresh_lock(string $currenciesCsv, int $waitSeconds = 5): bool {
  global $conn;

  $lockName = _lock_name($currenciesCsv);
  $stmt = $conn->prepare("SELECT GET_LOCK(?, ?)");
  $stmt->bind_param('si', $lockName, $waitSeconds);
  $stmt->execute();
  $stmt->bind_result($gotLock);
  $stmt->fetch();
  $stmt->close();

  return (int)$gotLock === 1;
}

function _release_refresh_lock(string $currenciesCsv): void {
  global $conn;

  $lockName = _lock_name($currenciesCsv);
  $stmt = $conn->prepare("SELECT RELEASE_LOCK(?)");
  $stmt->bind_param('s', $lockName);
  $stmt->execute();
  $stmt->close();
}

function http_get_json(string $url, int $timeoutSeconds = 15): array {
  if (function_exists('curl_init')) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_TIMEOUT        => $timeoutSeconds,
      CURLOPT_SSL_VERIFYPEER => true,
      CURLOPT_HTTPHEADER     => ['Accept: application/json'],
    ]);

    $resp = curl_exec($ch);
    $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);

    if ($resp === false || $http >= 400) {
      return ['ok' => false, 'error' => "HTTP $http: $err"];
    }

    $json = json_decode($resp, true);
    return ['ok' => is_array($json), 'json' => $json, 'error' => is_array($json) ? '' : 'Invalid JSON'];
  }

  $ctx = stream_context_create([
    'http' => [
      'timeout' => $timeoutSeconds,
      'header'  => "Accept: application/json\r\n",
    ]
  ]);

  $resp = @file_get_contents($url, false, $ctx);
  if ($resp === false) {
    return ['ok' => false, 'error' => 'HTTP request failed'];
  }

  $json = json_decode($resp, true);
  return ['ok' => is_array($json), 'json' => $json, 'error' => is_array($json) ? '' : 'Invalid JSON'];
}

/**
 * Returns MetalpriceAPI "latest" response JSON (cached + locked).
 */
function fetch_latest_rates(): array {
  $apiKey = get_metal_api_key();
  if ($apiKey === '') {
    return ['success' => false, 'error' => ['info' => 'API key missing in settings']];
  }

  $currencies = array_unique(array_merge(APP_CURRENCIES, APP_METALS));
  $csv = implode(',', $currencies);

  // 1) Fresh cache first
  $fresh = _load_fresh_cache($csv);
  if ($fresh) {
    return $fresh;
  }

  $lockWait = defined('RATES_LOCK_WAIT') ? (int)RATES_LOCK_WAIT : 5;
  $gotLock = _acquire_refresh_lock($csv, $lockWait);

  if ($gotLock) {
    try {
      // 2) Double-check after lock in case another request refreshed before us
      $fresh = _load_fresh_cache($csv);
      if ($fresh) {
        return $fresh;
      }

      $url = 'https://api.metalpriceapi.com/v1/latest?api_key=' . urlencode($apiKey)
           . '&base=USD&currencies=' . urlencode($csv);

      $r = http_get_json($url, 15);

      if (!empty($r['ok'])) {
        $json = $r['json'];

        if (is_array($json) && !empty($json['success'])) {
          _save_cache($csv, $json);
          return $json;
        }
      }

      // 3) Upstream failed -> return stale cache if available
      $stale = _load_stale_cache($csv);
      if ($stale) {
        return $stale;
      }

      return [
        'success' => false,
        'error'   => ['info' => $r['error'] ?? ($json['error']['info'] ?? 'Unknown API error')]
      ];
    } finally {
      _release_refresh_lock($csv);
    }
  }

  // 4) Another request is already refreshing. Wait briefly and try cache again.
  for ($i = 0; $i < 3; $i++) {
    usleep(500000); // 0.5 sec
    $fresh = _load_fresh_cache($csv);
    if ($fresh) {
      return $fresh;
    }
  }

  // 5) Still not refreshed -> return stale cache if available
  $stale = _load_stale_cache($csv);
  if ($stale) {
    return $stale;
  }

  return [
    'success' => false,
    'error'   => ['info' => 'Unable to refresh rates right now']
  ];
}