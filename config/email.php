<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */


return [
    'name' => 'Birthday event reminder',
    'description' => 'Birthday event reminder notification with queue',
    'templates' => [
        'member-birthday-reminder-notification' => [
            'title' => 'Birthday event reminder',
            'description' => 'Birthday event reminder notification with queue',
            'subject' => 'Birthday event reminder',
            'can_off' => false,
            'enabled' => true,
            'variables' => [
                'email' => 'Email'
            ],
        ],
    ],
];
