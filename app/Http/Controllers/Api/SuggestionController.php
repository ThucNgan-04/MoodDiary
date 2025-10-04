<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Suggestion;
use Illuminate\Http\Request;

class SuggestionController extends Controller
{
    public function index() { return response()->json(Suggestion::all()); }

    public function store(Request $request)
    {
        $suggestion = Suggestion::create($request->all());
        return response()->json($suggestion,201);
    }

    public function show($id) { return response()->json(Suggestion::findOrFail($id)); }

    public function update(Request $request,$id)
    {
        $s = Suggestion::findOrFail($id);
        $s->update($request->all());
        return response()->json($s);
    }

    public function destroy($id)
    {
        Suggestion::findOrFail($id)->delete();
        return response()->json(['message'=>'Xóa gợi ý thành công']);
    }
}