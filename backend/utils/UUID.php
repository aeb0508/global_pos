<?php

/**
 * UUID Generator Utility
 * Generates RFC 4122 compliant UUIDs (Version 4)
 */
class UUID {
    
    /**
     * Generate a UUID v4 (random)
     * Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
     * 
     * @return string UUID string (36 characters)
     */
    public static function generate() {
        // Generate 16 random bytes
        $data = random_bytes(16);
        
        // Set version to 0100 (UUID v4)
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        
        // Set bits 6-7 to 10
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        
        // Format as UUID string
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
    
    /**
     * Validate if a string is a valid UUID
     * 
     * @param string $uuid The UUID to validate
     * @return bool True if valid, false otherwise
     */
    public static function isValid($uuid) {
        $pattern = '/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i';
        return preg_match($pattern, $uuid) === 1;
    }
    
    /**
     * Generate a UUID from a string (UUID v5 - SHA1 hash)
     * Useful for generating deterministic UUIDs
     * 
     * @param string $namespace Namespace UUID
     * @param string $name Name to generate UUID from
     * @return string UUID string
     */
    public static function generateFromString($namespace, $name) {
        // Get hexadecimal components of namespace
        $nhex = str_replace(['-', '{', '}'], '', $namespace);
        
        // Binary Value
        $nstr = '';
        for ($i = 0; $i < strlen($nhex); $i += 2) {
            $nstr .= chr(hexdec($nhex[$i] . $nhex[$i + 1]));
        }
        
        // Calculate hash value
        $hash = sha1($nstr . $name);
        
        return sprintf(
            '%08s-%04s-%04x-%04x-%12s',
            substr($hash, 0, 8),
            substr($hash, 8, 4),
            (hexdec(substr($hash, 12, 4)) & 0x0fff) | 0x5000,
            (hexdec(substr($hash, 16, 4)) & 0x3fff) | 0x8000,
            substr($hash, 20, 12)
        );
    }
    
    /**
     * Convert UUID to binary format (for storage optimization)
     * 
     * @param string $uuid UUID string
     * @return string Binary representation
     */
    public static function toBinary($uuid) {
        return hex2bin(str_replace('-', '', $uuid));
    }
    
    /**
     * Convert binary UUID back to string format
     * 
     * @param string $binary Binary UUID
     * @return string UUID string
     */
    public static function fromBinary($binary) {
        $hex = bin2hex($binary);
        return sprintf(
            '%s-%s-%s-%s-%s',
            substr($hex, 0, 8),
            substr($hex, 8, 4),
            substr($hex, 12, 4),
            substr($hex, 16, 4),
            substr($hex, 20)
        );
    }
    
    /**
     * Generate multiple UUIDs at once
     * 
     * @param int $count Number of UUIDs to generate
     * @return array Array of UUID strings
     */
    public static function generateBatch($count) {
        $uuids = [];
        for ($i = 0; $i < $count; $i++) {
            $uuids[] = self::generate();
        }
        return $uuids;
    }
}
