<?php

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
