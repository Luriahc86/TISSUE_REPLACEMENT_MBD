<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class LaporanController extends Controller
{
    // Ambil semua laporan
    public function index()
    {
        $data = DB::table('v_laporan_pegawai')->get();

        return response()->json([
            'status' => 'success',
            'total' => $data->count(),
            'data' => $data
        ], 200);
    }

    // Ambil laporan per pegawai (optional)
    public function show($id)
    {
        $data = DB::table('v_laporan_pegawai')->where('id_pegawai', $id)->get();

        if ($data->isEmpty()) {
            return response()->json(['status' => 'not found'], 404);
        }

        return response()->json([
            'status' => 'success',
            'total' => $data->count(),
            'data' => $data
        ]);
    }
}
