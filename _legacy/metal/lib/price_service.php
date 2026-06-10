<?php
// metal/lib/price_service.php
require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/metalprice_client.php';

function usd_oz_to_cur(float $usdPerOz, float $usdToCur): float {
  return $usdPerOz * $usdToCur;
}

function apply_adjustment(float $base, float $percent, float $flat): float {
  return ($base * (1 + ($percent / 100.0))) + $flat;
}

function get_adjustment(string $metal, string $currency): array {
  global $conn;
  $stmt = $conn->prepare("
    SELECT
      percent_adjust, flat_adjust,
      sell_percent_adjust, sell_flat_adjust,
      buy_percent_adjust,  buy_flat_adjust
    FROM price_adjustments
    WHERE metal_code=? AND currency_code=?
    LIMIT 1
  ");
  $stmt->bind_param('ss', $metal, $currency);
  $stmt->execute();
  $stmt->bind_result($p, $f, $sp, $sf, $bp, $bf);

  if ($stmt->fetch()) {
    $stmt->close();
    return [
      'mid_percent'  => (float)$p,
      'mid_flat'     => (float)$f,
      'sell_percent' => (float)$sp,
      'sell_flat'    => (float)$sf,
      'buy_percent'  => (float)$bp,
      'buy_flat'     => (float)$bf,
    ];
  }

  $stmt->close();
  return [
    'mid_percent'  => 0.0, 'mid_flat'  => 0.0,
    'sell_percent' => 0.0, 'sell_flat' => 0.0,
    'buy_percent'  => 0.0, 'buy_flat'  => 0.0,
  ];
}

/**
 * Gold-karat adjustments for a currency.
 * karat_code: 18K, 21K, 22K, 24K, RAWA
 */
function get_gold_karat_adjustments(string $currency): array {
  global $conn;

  $out = [];
  $stmt = $conn->prepare("
    SELECT
      karat_code,
      mid_percent_adjust,  mid_flat_adjust,
      sell_percent_adjust, sell_flat_adjust,
      buy_percent_adjust,  buy_flat_adjust
    FROM gold_karat_adjustments
    WHERE currency_code=?
  ");
  $stmt->bind_param('s', $currency);
  $stmt->execute();
  $stmt->bind_result($karat, $mp, $mf, $sp, $sf, $bp, $bf);

  while ($stmt->fetch()) {
    $out[$karat] = [
      'mid_percent'  => (float)$mp,
      'mid_flat'     => (float)$mf,
      'sell_percent' => (float)$sp,
      'sell_flat'    => (float)$sf,
      'buy_percent'  => (float)$bp,
      'buy_flat'     => (float)$bf,
    ];
  }
  $stmt->close();
  return $out;
}

/**
 * Silver quantity adjustments for a currency.
 * qty_code (recommended): GRAM, G10, TOLA, T10, KG
 */
function get_silver_qty_adjustments(string $currency): array {
  global $conn;

  $out = [];
  $stmt = $conn->prepare("
    SELECT
      qty_code,
      mid_percent_adjust,  mid_flat_adjust,
      sell_percent_adjust, sell_flat_adjust,
      buy_percent_adjust,  buy_flat_adjust
    FROM silver_qty_adjustments
    WHERE currency_code=?
  ");
  $stmt->bind_param('s', $currency);
  $stmt->execute();
  $stmt->bind_result($qty, $mp, $mf, $sp, $sf, $bp, $bf);

  while ($stmt->fetch()) {
    $out[$qty] = [
      'mid_percent'  => (float)$mp,
      'mid_flat'     => (float)$mf,
      'sell_percent' => (float)$sp,
      'sell_flat'    => (float)$sf,
      'buy_percent'  => (float)$bp,
      'buy_flat'     => (float)$bf,
    ];
  }
  $stmt->close();
  return $out;
}

function build_response(string $currency): array {
  $raw = fetch_latest_rates();
  if (empty($raw['success'])) return $raw;

  $rates = $raw['rates'] ?? [];
  $usdToCur = $rates[$currency] ?? null;
  if (!$usdToCur) {
    return ['success'=>false,'error'=>['info'=>"Target currency $currency missing in rates"]];
  }

  // Metals USD/oz (troy ounce)
  $mapUsd = [
    'XAU' => $rates['USDXAU'] ?? null,
    'XAG' => $rates['USDXAG'] ?? null,
    'XPT' => $rates['USDXPT'] ?? null,
    'XPD' => $rates['USDXPD'] ?? null,
  ];

  $GRAMS_PER_TROY_OZ = 31.1034768;
  $TOLA_GRAMS        = 11.6638038;

  $out = [
    'success'   => true,
    'timestamp' => $raw['timestamp'] ?? time(),
    'currency'  => $currency,
    'metals'    => [],
  ];

  // preload adjustments once per request
  $goldKaratAdj  = get_gold_karat_adjustments($currency);
  $silverQtyAdj  = get_silver_qty_adjustments($currency);

  foreach ($mapUsd as $code => $usdPerOz) {
    if (!$usdPerOz) continue;

    $baseCurPerOz = usd_oz_to_cur((float)$usdPerOz, (float)$usdToCur);

    $adj = get_adjustment($code, $currency);

    // MID then SELL/BUY on top of MID
    $midPerOz  = apply_adjustment($baseCurPerOz, $adj['mid_percent'],  $adj['mid_flat']);
    $sellPerOz = apply_adjustment($midPerOz,     $adj['sell_percent'], $adj['sell_flat']);
    $buyPerOz  = apply_adjustment($midPerOz,     $adj['buy_percent'],  $adj['buy_flat']);

    $midPerGram  = $midPerOz  / $GRAMS_PER_TROY_OZ;
    $sellPerGram = $sellPerOz / $GRAMS_PER_TROY_OZ;
    $buyPerGram  = $buyPerOz  / $GRAMS_PER_TROY_OZ;

    $midPerTola  = $midPerGram  * $TOLA_GRAMS;
    $sellPerTola = $sellPerGram * $TOLA_GRAMS;
    $buyPerTola  = $buyPerGram  * $TOLA_GRAMS;

    $item = [
      'code' => $code,
      'name' => ['XAU'=>'Gold','XAG'=>'Silver','XPT'=>'Platinum','XPD'=>'Palladium'][$code],

      // Backward-compatible MID fields
      'per_oz'   => round($midPerOz,   4),
      'per_gram' => round($midPerGram, 4),
      'per_tola' => round($midPerTola, 4),

      // SELL/BUY blocks
      'sell' => [
        'per_oz'   => round($sellPerOz,   4),
        'per_gram' => round($sellPerGram, 4),
        'per_tola' => round($sellPerTola, 4),
      ],
      'buy' => [
        'per_oz'   => round($buyPerOz,   4),
        'per_gram' => round($buyPerGram, 4),
        'per_tola' => round($buyPerTola, 4),
      ],

      'adjustment' => [
        'mid'  => ['percent'=>$adj['mid_percent'],  'flat'=>$adj['mid_flat']],
        'sell' => ['percent'=>$adj['sell_percent'], 'flat'=>$adj['sell_flat']],
        'buy'  => ['percent'=>$adj['buy_percent'],  'flat'=>$adj['buy_flat']],
      ],
    ];

    // GOLD categories (per gram) for MID/SELL/BUY — adjustable per category
    if ($code === 'XAU') {
      // base ratios from 24K
      $karats = [
        '24K'  => 24/24.0,
        '22K'  => 22/24.0,
        '21K'  => 21/24.0,
        '18K'  => 18/24.0,
        'RAWA' => 1.0, // ✅ Rawa base = same as 24K (still adjustable separately)
      ];

      $item['gold_by_karat_per_gram'] = [];
      $item['gold_by_karat_per_gram_sell'] = [];
      $item['gold_by_karat_per_gram_buy'] = [];

      foreach ($karats as $kcode => $ratio) {
        $baseMid  = $midPerGram  * $ratio;
        $baseSell = $sellPerGram * $ratio;
        $baseBuy  = $buyPerGram  * $ratio;

        $ka = $goldKaratAdj[$kcode] ?? [
          'mid_percent'  => 0.0, 'mid_flat'  => 0.0,
          'sell_percent' => 0.0, 'sell_flat' => 0.0,
          'buy_percent'  => 0.0, 'buy_flat'  => 0.0,
        ];

        $mid  = apply_adjustment($baseMid,  $ka['mid_percent'],  $ka['mid_flat']);
        $sell = apply_adjustment($baseSell, $ka['sell_percent'], $ka['sell_flat']);
        $buy  = apply_adjustment($baseBuy,  $ka['buy_percent'],  $ka['buy_flat']);

        // API key for RAWA should be "Rawa" (app-friendly)
        $outKey = ($kcode === 'RAWA') ? 'Rawa' : $kcode;

        $item['gold_by_karat_per_gram'][$outKey]      = round($mid,  4);
        $item['gold_by_karat_per_gram_sell'][$outKey] = round($sell, 4);
        $item['gold_by_karat_per_gram_buy'][$outKey]  = round($buy,  4);
      }

      $item['gold_karat_adjustments'] = $goldKaratAdj;
    }

    // ✅ SILVER quantities — adjustable per quantity (Gram, 10 Gram, Tola, 10 Tola, 1 KG)
    if ($code === 'XAG') {
      $qtyDefs = [
        'GRAM' => ['label' => 'Gram',    'grams' => 1.0],
        'G10'  => ['label' => '10 Gram', 'grams' => 10.0],
        'TOLA' => ['label' => 'Tola',    'grams' => $TOLA_GRAMS],
        'T10'  => ['label' => '10 Tola', 'grams' => $TOLA_GRAMS * 10.0],
        'KG'   => ['label' => '1 KG',    'grams' => 1000.0],
      ];

      $item['silver_by_qty'] = [];       // MID
      $item['silver_by_qty_sell'] = [];
      $item['silver_by_qty_buy']  = [];

      foreach ($qtyDefs as $qcode => $def) {
        $label = $def['label'];
        $grams = (float)$def['grams'];

        // base values from the already-adjusted metal mid/sell/buy per gram
        $baseMid  = $midPerGram  * $grams;
        $baseSell = $sellPerGram * $grams;
        $baseBuy  = $buyPerGram  * $grams;

        $qa = $silverQtyAdj[$qcode] ?? [
          'mid_percent'  => 0.0, 'mid_flat'  => 0.0,
          'sell_percent' => 0.0, 'sell_flat' => 0.0,
          'buy_percent'  => 0.0, 'buy_flat'  => 0.0,
        ];

        $mid  = apply_adjustment($baseMid,  $qa['mid_percent'],  $qa['mid_flat']);
        $sell = apply_adjustment($baseSell, $qa['sell_percent'], $qa['sell_flat']);
        $buy  = apply_adjustment($baseBuy,  $qa['buy_percent'],  $qa['buy_flat']);

        // Use human-friendly keys that match your app UI labels
        $item['silver_by_qty'][$label]       = round($mid,  4);
        $item['silver_by_qty_sell'][$label]  = round($sell, 4);
        $item['silver_by_qty_buy'][$label]   = round($buy,  4);
      }

      $item['silver_qty_adjustments'] = $silverQtyAdj;
    }

    $out['metals'][] = $item;
  }

  return $out;
}
