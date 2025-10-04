<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Setting;

class SettingController extends Controller
{
    /**
     * Lấy cài đặt của người dùng hiện tại
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSettings(Request $request)
    {
        // Lấy người dùng đã xác thực
        $user = Auth::user();
        
        // Lấy hoặc tạo cài đặt mặc định nếu chưa có
        $settings = Setting::firstOrCreate(
            ['user_id' => $user->id],
            [
                'language' => 'vi',
                'font_size' => 'medium',
                'theme' => 'light',
                'color_theme' => '#FFC0CB',
                'notify_daily' => true,
            ]
        );

        return response()->json([
            'message' => 'Lấy cài đặt thành công',
            'settings' => $settings
        ]);
    }

    /**
     * Cập nhật cài đặt của người dùng hiện tại
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateSettings(Request $request)
    {
        $user = Auth::user();
        
        // Lấy cài đặt hiện có của người dùng
        $settings = $user->setting;

        if (!$settings) {
            return response()->json([
                'message' => 'Cài đặt không tồn tại',
            ], 404);
        }

        // Cập nhật các trường cài đặt dựa trên dữ liệu từ request
        $settings->update($request->all());

        return response()->json([
            'message' => 'Cập nhật cài đặt thành công',
            'settings' => $settings
        ]);
    }
}