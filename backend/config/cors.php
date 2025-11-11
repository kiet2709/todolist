<?php
// config/cors.php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. Adjust to match your frontend origin in production.
    |
    */

    // Áp dụng cho những đường dẫn nào (wildcard '*')
    'paths' => ['api/*', 'sanctum/csrf-cookie', '*'],

    // Phương thức cho phép
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    // Origins được phép (DEV: thêm origin của Vite/FE)
    'allowed_origins' => [
        'http://localhost:5173',      // Vite dev mặc định — thay nếu bạn dùng port khác
        'http://127.0.0.1:5173',
        'http://localhost',           // tùy vào cách bạn gọi, giữ 1-2 giá trị dev
        'http://127.0.0.1'
        // 'https://your.prod.frontend.com' // production
    ],

    // Allow origin pattern (nếu cần regex)
    'allowed_origins_patterns' => [],

    // Headers cho phép (giữ * cho dev)
    'allowed_headers' => ['*'],

    // Headers mà browser được phép đọc
    'exposed_headers' => [],

    // Cache preflight (giây)
    'max_age' => 0,

    // Nếu bạn muốn truyền cookie/credential (true nếu dùng cookie-based auth)
    'supports_credentials' => false,
];
