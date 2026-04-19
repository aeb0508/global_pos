<?php

require_once __DIR__ . '/../config/Config.php';

class JWT {
    private static $encrypt = 'HS256';
    private static $aud = null;

    private static function getSecretKey() {
        $key = defined('JWT_SECRET') ? JWT_SECRET : Config::get('JWT_SECRET_KEY', '0699c6ddeaec48d82dfae8a2fb3111d74f3d99cca887a7ab837b3c3a628cdb6a');
        if (empty($key)) $key = '0699c6ddeaec48d82dfae8a2fb3111d74f3d99cca887a7ab837b3c3a628cdb6a';
        return $key;
    }

    public static function encode($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => self::$encrypt]);
        $payload = json_encode($payload);
        
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::getSecretKey(), true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function decode($jwt) {
        $tokenParts = explode('.', $jwt);
        if (count($tokenParts) != 3) {
            return false;
        }
        
        $header = base64_decode($tokenParts[0]);
        $payload = base64_decode($tokenParts[1]);
        $signatureProvided = $tokenParts[2];

        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::getSecretKey(), true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        if ($base64UrlSignature !== $signatureProvided) {
            return false;
        }

        return json_decode($payload, true);
    }
}
