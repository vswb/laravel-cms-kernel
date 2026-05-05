<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

namespace Dev\Kernel\Http\Controllers\API;

use Dev\Base\Http\Controllers\BaseController;
use Illuminate\Http\Request;

class LicenseServerController extends BaseController
{
    /**
     * Handle license activation heartbeats from client domains.
     */
    public function activate(Request $request)
    {
        return response()->json([
            'status' => true,
            'message' => 'License processed.',
            'lic_response' => '',
        ]);
    }

    /**
     * Handle core version check (check_update).
     */
    public function checkUpdate(Request $request)
    {
        return response()->json([
            'status' => true,
            'data' => null,
            'message' => 'Congratulations! Your core system is running the latest official version.',
        ]);
    }

    /**
     * Handle license verification check (verify_license).
     */
    public function verify(Request $request)
    {
        return response()->json([
            'status' => true,
            'message' => 'License verified.',
            'lic_response' => '',
        ]);
    }

    /**
     * Basic connection check.
     */
    public function checkConnection(Request $request)
    {
        return response()->json(['status' => true]);
    }

    /**
     * Extended connection check (check_connection_ext).
     */
    public function checkConnectionExt(Request $request)
    {
        return response()->json([
            'status' => true,
            'message' => 'Connection established successfully.',
        ]);
    }

    /**
     * Silent tracker for unauthorized or unverified check-ins.
     */
    public static function trackUsage(Request $request, string $type = 'CHECK_UPDATE', array $extra = [])
    {
        // Removed tracking logic
    }
}
