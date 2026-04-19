<?php
// Professional PDF Receipt Generator — pure PHP, no dependencies

require_once __DIR__ . '/../config/Config.php';

function generateReceiptPdf($orderId, $customer, $orderData, $items = []) {
    $W = 595; $H = 842;
    $m = 40;

    $pdf = new _PDF($W, $H);

    // Get company branding from config
    $companyName = strtoupper(Config::get('COMPANY_NAME', 'Global POS'));
    $companyTagline = Config::get('COMPANY_TAGLINE', 'Point of Sale System');

    // ── HEADER ─────────────────────────────────────────────────────
    $pdf->rect(0, $H - 85, $W, 85, '1A3A6B');           // dark blue bg
    $pdf->rect(0, $H - 88, $W, 3,  'F5B800');           // gold line

    $pdf->text($companyName, 26, true,  'C', 'FFFFFF', $H - 42);
    $pdf->text($companyTagline, 10, false, 'C', 'B0C4DE', $H - 60);
    $pdf->text('RECEIPT', 16, true, 'R', 'F5B800', $H - 45, $m);

    // ── ORDER INFO BOX ─────────────────────────────────────────────
    $boxY = $H - 165;
    $pdf->rect($m, $boxY, $W - $m * 2, 65, 'EEF2F7');
    $pdf->rectBorder($m, $boxY, $W - $m * 2, 65, 'C5D0DE');

    // Left column
    $pdf->text('ORDER NUMBER', 8, true,  'L', '1A3A6B', $boxY + 50, $m + 10);
    $pdf->text('#' . str_pad($orderId, 6, '0', STR_PAD_LEFT), 14, true, 'L', '1A1A1A', $boxY + 32, $m + 10);

    // Middle column
    $midX = $m + 160;
    $pdf->text('DATE & TIME', 8, true,  'L', '1A3A6B', $boxY + 50, $midX);
    $pdf->text(date('d M Y'), 11, true, 'L', '1A1A1A', $boxY + 34, $midX);
    $pdf->text(date('H:i:s'), 9, false, 'L', '555555', $boxY + 22, $midX);

    // Right column
    $rightX = $m + 320;
    $pdf->text('CUSTOMER', 8, true,  'L', '1A3A6B', $boxY + 50, $rightX);
    $pdf->text(_esc($customer['name'] ?? 'Walk-in Customer'), 10, true, 'L', '1A1A1A', $boxY + 34, $rightX);
    $pdf->text(_esc($customer['email'] ?? 'No email'), 8, false, 'L', '555555', $boxY + 22, $rightX);
    $pdf->text(_esc($customer['phone'] ?? ''), 8, false, 'L', '555555', $boxY + 12, $rightX);

    // ── ITEMS TABLE HEADER ─────────────────────────────────────────
    $tableTopY = $boxY - 20;
    $pdf->rect($m, $tableTopY - 4, $W - $m * 2, 22, '1A3A6B');
    $pdf->text('DESCRIPTION',  8, true, 'L', 'FFFFFF', $tableTopY + 5,  $m + 8);
    $pdf->text('QTY',          8, true, 'L', 'FFFFFF', $tableTopY + 5,  290);
    $pdf->text('UNIT PRICE',   8, true, 'L', 'FFFFFF', $tableTopY + 5,  340);
    $pdf->text('DISCOUNT',     8, true, 'L', 'FFFFFF', $tableTopY + 5,  415);
    $pdf->text('TOTAL',        8, true, 'R', 'FFFFFF', $tableTopY + 5,  $m, $W - $m - 8);

    // ── ITEMS ROWS ─────────────────────────────────────────────────
    $rowY = $tableTopY - 4;
    $alt  = false;
    foreach ($items as $item) {
        $rowY -= 22;
        if ($alt) $pdf->rect($m, $rowY, $W - $m * 2, 22, 'F4F6FA');
        $alt = !$alt;

        $name     = _esc(mb_strimwidth($item['name'] ?? 'Item', 0, 38, '...'));
        $qty      = $item['quantity'] ?? 1;
        $unitP    = '$' . number_format($item['unit_price'] ?? 0, 2);
        $disc     = isset($item['discount']) && $item['discount'] > 0
                    ? '-$' . number_format($item['discount'], 2) : '-';
        $lineTotal = '$' . number_format($item['total_price'] ?? 0, 2);

        $pdf->text($name,      9, false, 'L', '1A1A1A', $rowY + 7,  $m + 8);
        $pdf->text($qty,       9, false, 'L', '1A1A1A', $rowY + 7,  290);
        $pdf->text($unitP,     9, false, 'L', '1A1A1A', $rowY + 7,  340);
        $pdf->text($disc,      9, false, 'L', 'CC2222', $rowY + 7,  415);
        $pdf->text($lineTotal, 9, true,  'R', '1A3A6B', $rowY + 7,  $m, $W - $m - 8);

        // row divider
        $pdf->line($m, $rowY, $W - $m, $rowY, 'DDDDDD');
    }

    // ── TOTALS ─────────────────────────────────────────────────────
    $totY = $rowY - 25;
    $lx   = 340; $rx = $W - $m;

    // Subtotal line
    $pdf->text('Subtotal:', 10, false, 'L', '444444', $totY, $lx);
    $pdf->text('$' . number_format($orderData['subtotal'] ?? 0, 2), 10, false, 'R', '1A1A1A', $totY, $m, $rx);
    $totY -= 18;

    if (!empty($orderData['discount']) && $orderData['discount'] > 0) {
        $pdf->text('Discount:', 10, false, 'L', 'CC2222', $totY, $lx);
        $pdf->text('-$' . number_format($orderData['discount'], 2), 10, false, 'R', 'CC2222', $totY, $m, $rx);
        $totY -= 18;
    }

    if (!empty($orderData['tax']) && $orderData['tax'] > 0) {
        $pdf->text('Tax:', 10, false, 'L', '444444', $totY, $lx);
        $pdf->text('$' . number_format($orderData['tax'], 2), 10, false, 'R', '1A1A1A', $totY, $m, $rx);
        $totY -= 18;
    }

    // Divider
    $pdf->line($lx, $totY + 4, $rx, $totY + 4, '1A3A6B', 1.5);
    $totY -= 22;

    // TOTAL box
    $pdf->rect($lx - 5, $totY - 6, $rx - $lx + 5, 26, '1A3A6B');
    $pdf->text('TOTAL', 13, true, 'L', 'FFFFFF', $totY + 4, $lx + 4);
    $pdf->text('$' . number_format($orderData['total'] ?? 0, 2), 13, true, 'R', 'F5B800', $totY + 4, $m, $rx - 4);
    $totY -= 28;

    // Payment method badge
    $pay = strtoupper(_esc($orderData['payment_method'] ?? 'N/A'));
    $pdf->text('Payment Method:', 10, false, 'L', '444444', $totY, $lx);
    $pdf->rect($rx - 70, $totY - 4, 70, 18, '1A3A6B');
    $pdf->text($pay, 9, true, 'C', 'FFFFFF', $totY + 2, $rx - 70, $rx);
    $totY -= 28;

    // ── NOTES / THANK YOU BOX ──────────────────────────────────────
    $noteY = $totY - 20;
    $pdf->rect($m, $noteY - 10, $W - $m * 2, 50, 'FFF8E7');
    $pdf->rectBorder($m, $noteY - 10, $W - $m * 2, 50, 'F5B800');
    $pdf->text('Thank you for your purchase!', 11, true,  'C', '1A3A6B', $noteY + 24);
    $pdf->text('We appreciate your business. Please keep this receipt for your records.', 9, false, 'C', '555555', $noteY + 10);
    $pdf->text('For any queries, please contact us with your order number.', 9, false, 'C', '555555', $noteY - 1);

    // ── FOOTER ─────────────────────────────────────────────────────
    $pdf->rect(0, 0, $W, 38, '1A3A6B');
    $pdf->rect(0, 38, $W, 3, 'F5B800');
    $footerText = Config::get('COMPANY_NAME', 'Global POS') . ' System  |  Professional Point of Sale';
    $pdf->text($footerText, 9, false, 'C', 'B0C4DE', 22);
    $pdf->text('This is an official receipt. Thank you for choosing ' . Config::get('COMPANY_NAME', 'Global POS') . '.', 8, false, 'C', '7A9BBF', 10);

    return $pdf->output();
}

// ── Minimal PDF engine ─────────────────────────────────────────────
class _PDF {
    private $W, $H, $ops = [];

    public function __construct($w, $h) { $this->W = $w; $this->H = $h; }

    public function rect($x, $y, $w, $h, $hex) {
        [$r,$g,$b] = _hex($hex);
        $this->ops[] = "{$r} {$g} {$b} rg {$x} {$y} {$w} {$h} re f";
    }

    public function rectBorder($x, $y, $w, $h, $hex, $lw = 0.5) {
        [$r,$g,$b] = _hex($hex);
        $this->ops[] = "{$r} {$g} {$b} RG {$lw} w {$x} {$y} {$w} {$h} re s";
    }

    public function line($x1, $y1, $x2, $y2, $hex, $lw = 0.5) {
        [$r,$g,$b] = _hex($hex);
        $this->ops[] = "{$r} {$g} {$b} RG {$lw} w {$x1} {$y1} m {$x2} {$y2} l s";
    }

    // text($str, $size, $bold, $align, $hex, $y, $x1=margin, $x2=null)
    public function text($text, $size, $bold, $align, $hex, $y, $x1 = 40, $x2 = null) {
        [$r,$g,$b] = _hex($hex);
        $font = $bold ? 'F2' : 'F1';
        $text = _esc((string)$text);
        $charW = $size * 0.52;
        $textW = strlen($text) * $charW;

        if ($align === 'C') {
            $containerW = ($x2 ?? $this->W - $x1) - $x1;
            $x = $x1 + ($containerW - $textW) / 2;
        } elseif ($align === 'R') {
            $x = ($x2 ?? $this->W - $x1) - $textW;
        } else {
            $x = $x1;
        }

        $this->ops[] = "BT /{$font} {$size} Tf {$r} {$g} {$b} rg {$x} {$y} Td ({$text}) Tj ET";
    }

    public function output() {
        $stream = implode("\n", $this->ops);
        $objs = [];
        $objs[1] = "<< /Type /Catalog /Pages 2 0 R >>";
        $objs[2] = "<< /Type /Pages /Kids [3 0 R] /Count 1 >>";
        $objs[3] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {$this->W} {$this->H}] /Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>";
        $objs[4] = "<< /Length " . strlen($stream) . " >>\nstream\n{$stream}\nendstream";
        $objs[5] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>";
        $objs[6] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>";

        $pdf = "%PDF-1.4\n";
        $off = [];
        foreach ($objs as $n => $o) { $off[$n] = strlen($pdf); $pdf .= "{$n} 0 obj\n{$o}\nendobj\n"; }
        $xref = strlen($pdf);
        $pdf .= "xref\n0 " . (count($objs) + 1) . "\n0000000000 65535 f \n";
        foreach ($off as $o) $pdf .= str_pad($o, 10, '0', STR_PAD_LEFT) . " 00000 n \n";
        $pdf .= "trailer\n<< /Size " . (count($objs) + 1) . " /Root 1 0 R >>\nstartxref\n{$xref}\n%%EOF";
        return $pdf;
    }
}

function _hex($hex) {
    $hex = ltrim($hex, '#');
    return [
        round(hexdec(substr($hex,0,2))/255, 3),
        round(hexdec(substr($hex,2,2))/255, 3),
        round(hexdec(substr($hex,4,2))/255, 3),
    ];
}

function _esc($t) {
    return str_replace(['\\','(',')'], ['\\\\','\\(','\\)'], (string)$t);
}
