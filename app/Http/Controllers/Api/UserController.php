<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    public function updateAvatar(Request $request)
    {
        $user = $request->user();

        if ($request->hasFile('avatar')) {
            // Xóa ảnh cũ nếu có
            if ($user->avatar && Storage::exists('public/avatars/' . $user->avatar)) {
                Storage::delete('public/avatars/' . $user->avatar);
            }

            $file = $request->file('avatar');
            $filename = time() . '_' . $file->getClientOriginalName();
            $file->storeAs('public/avatars', $filename);

            $user->avatar = $filename;
            $user->save();

            return response()->json([
                'message' => 'Cập nhật ảnh đại diện thành công.',
                'avatar_url' => asset('storage/avatars/' . $filename),
            ]);
        }

        return response()->json(['error' => 'Không có file nào được tải lên.'], 400);
    }
}