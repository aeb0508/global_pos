<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
echo json_encode(['status' => 'ok', 'message' => 'Global POS API is running']);
