<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Setting; // Đảm bảo đã import Setting model
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Laravel\Passport\HasApiTokens;
use Illuminate\Notifications\Notifiable;

class AuthController extends Controller
{
    use HasApiTokens, Notifiable;
    
    //-------------------------------------------//
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|unique:users',
            'password' => 'required|string|min:6',
        ]);

        // Tạo người dùng mới
        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Tạo bản ghi cài đặt mặc định cho người dùng
        $user->setting()->create([
            'user_id' => $user->id,
            'language' => 'vi',
            'font_size' => 'medium',
            'theme' => 'light',
            'notify_daily' => true,
        ]);

        $token = $user->createToken('LaravelPassportToken')->accessToken;

        return response()->json([
            'message' => 'Đăng ký thành công',
            'token' => $token,
            'user' => $user
        ], 201);
    }
    
    //-------------------------------------------//
    public function login(Request $request)
    {
        if (Auth::attempt(['email' => $request->email, 'password' => $request->password])) {
            $user  = Auth::user();
            $token = $user->createToken('LaravelPassportToken')->accessToken;
            return response()->json([
                'message'=> 'Đăng nhập thành công',
                'token' => $token,
                'user' => $user //import thông tin
            ], 200);
        } else {
            return response()->json(['error' => 'Sai email hoặc mật khẩu ♥'], 401);
        }
    }

    //-------------------------------------------//
    public function logout(Request $request)
    {
        $request->user()->token()->revoke();
        return response()->json([
            'message' => 'Đăng xuất thành công ♥'
        ]);
    }

    //-------------------------------------------//
    public function user(Request $request)
    {
        return response()->json([
            'message' => 'Thông tin người dùng hiện tại',
            'user' => $request->user()->load('setting')
        ]);
    }

    //-------------------------------------------//
    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|string|min:6',
        ]);

        $user = $request->user();

        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json(['error' => 'Mật khẩu cũ không đúng'], 400);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json(['message' => 'Đổi mật khẩu thành công']);
    }

    public function updateProfile(Request $request)
    {
        //Xác thực dl
        $request->validate([
            'name' => 'required|string|max:255', 
        ]);

        $user = $request->user();

        //Cập nhật tt
        $user->update([
            'name' => $request->name,
        ]);

        return response()->json([
            'message' => 'Cập nhật thông tin cá nhân thành công',
            'user' => $user->load('setting')
        ]);
    }
}