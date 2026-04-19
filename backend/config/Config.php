<?php

class Config {
    private static $config = null;
    private static $loaded = false;

    public static function load() {
        if (self::$loaded) return;
        
        self::$config = [];
        $envFile = __DIR__ . '/../.env';
        
        if (file_exists($envFile)) {
            $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if (empty($line) || strpos($line, '#') === 0) continue;
                
                if (strpos($line, '=') !== false) {
                    list($key, $value) = explode('=', $line, 2);
                    self::$config[trim($key)] = trim($value);
                }
            }
        }
        
        self::$loaded = true;
    }

    public static function get($key, $default = null) {
        self::load();

        // Support environment-specific database profiles.
        if (in_array($key, ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'], true)) {
            $env = strtolower(self::$config['DB_ENV'] ?? self::$config['APP_ENV'] ?? 'development');
            if (in_array($env, ['production', 'prod', 'infinityfree'], true)) {
                $profileKey = $key . '_PROD';
                if (isset(self::$config[$profileKey])) {
                    return self::$config[$profileKey];
                }
                $profileKey = $key . '_INFINITYFREE';
                if (isset(self::$config[$profileKey])) {
                    return self::$config[$profileKey];
                }
            } else {
                $profileKey = $key . '_LOCAL';
                if (isset(self::$config[$profileKey])) {
                    return self::$config[$profileKey];
                }
                $profileKey = $key . '_DEV';
                if (isset(self::$config[$profileKey])) {
                    return self::$config[$profileKey];
                }
            }
        }

        return self::$config[$key] ?? $default;
    }

    public static function getInt($key, $default = 0) {
        return (int)self::get($key, $default);
    }

    public static function getBool($key, $default = false) {
        $value = self::get($key, $default);
        if (is_bool($value)) return $value;
        return in_array(strtolower($value), ['true', '1', 'yes', 'on']);
    }
}
