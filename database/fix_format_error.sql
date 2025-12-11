-- ============================================
-- FIX: Format Error di submit_attendance Function
-- ============================================
-- Error: "unrecognized format() type specifier "."
-- 
-- Masalah: PostgreSQL format() function tidak support
--          format specifier seperti %.0f (C-style printf)
-- 
-- Solusi: Ganti dengan string concatenation
-- ============================================

-- Update function submit_attendance
CREATE OR REPLACE FUNCTION submit_attendance(
    p_qr_secret TEXT,
    p_user_lat DOUBLE PRECISION,
    p_user_long DOUBLE PRECISION,
    p_scan_type TEXT DEFAULT 'CHECK_IN_SCHOOL'
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_room_id INTEGER;
    v_room_lat DOUBLE PRECISION;
    v_room_long DOUBLE PRECISION;
    v_radius INTEGER;
    v_dist_meters DOUBLE PRECISION;
    v_room_name TEXT;
    v_existing_log_id BIGINT;
BEGIN
    -- 1. Ambil User ID dari sesi login
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'User tidak terautentikasi!'
        );
    END IF;
    
    -- 2. Validasi QR Code
    SELECT id, latitude, longitude, radius_meter, name
    INTO v_room_id, v_room_lat, v_room_long, v_radius, v_room_name
    FROM classrooms
    WHERE qr_secret = p_qr_secret AND is_active = TRUE;
    
    IF v_room_id IS NULL THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'QR Code tidak dikenali atau tidak aktif!'
        );
    END IF;
    
    -- 3. Hitung Jarak menggunakan Haversine Formula (dalam meter)
    v_dist_meters := (
        6371000 * acos(
            LEAST(1.0, 
                cos(radians(p_user_lat)) * cos(radians(v_room_lat)) *
                cos(radians(v_room_long) - radians(p_user_long)) +
                sin(radians(p_user_lat)) * sin(radians(v_room_lat))
            )
        )
    );
    
    -- 4. Validasi Geofencing
    IF v_dist_meters > v_radius THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Lokasi Anda terlalu jauh (' || ROUND(v_dist_meters)::text || ' meter). Harap mendekat ke titik scan. Jarak maksimal: ' || v_radius::text || ' meter.',
            'distance_meters', v_dist_meters,
            'max_radius', v_radius
        );
    END IF;
    
    -- 5. Cek apakah sudah ada scan hari ini dengan scan_type yang sama
    SELECT id INTO v_existing_log_id
    FROM attendance_logs
    WHERE teacher_id = v_user_id
        AND room_id = v_room_id
        AND scan_type = p_scan_type
        AND DATE(scan_time) = CURRENT_DATE
    LIMIT 1;
    
    IF v_existing_log_id IS NOT NULL THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Anda sudah melakukan scan ' || p_scan_type || ' hari ini di lokasi ini.'
        );
    END IF;
    
    -- 6. Insert Log (Jika Lolos)
    INSERT INTO attendance_logs (
        teacher_id, 
        room_id, 
        scan_time, 
        scan_type, 
        gps_lat, 
        gps_long, 
        status,
        distance_meters
    )
    VALUES (
        v_user_id, 
        v_room_id, 
        NOW(), 
        p_scan_type, 
        p_user_lat, 
        p_user_long, 
        'VALID',
        v_dist_meters
    );
    
    RETURN json_build_object(
        'status', 'success',
        'message', 'Presensi berhasil dicatat di ' || v_room_name || '!',
        'room_name', v_room_name,
        'distance_meters', v_dist_meters,
        'scan_type', p_scan_type
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Terjadi kesalahan: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verifikasi function
SELECT 
    'Function submit_attendance: ' || 
    CASE WHEN EXISTS (
        SELECT FROM pg_proc 
        WHERE proname = 'submit_attendance'
    ) THEN '✅ Diperbarui' ELSE '❌ Tidak ditemukan' END as status;

