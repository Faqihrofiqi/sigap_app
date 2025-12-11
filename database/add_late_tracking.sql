-- ============================================
-- Migration: Add Late Tracking Feature
-- Menambahkan fitur tracking keterlambatan
-- ============================================

-- 1. Tambahkan kolom late_tolerance_minutes di tabel schedules
-- Default 10 menit toleransi
ALTER TABLE schedules 
ADD COLUMN IF NOT EXISTS late_tolerance_minutes INTEGER NOT NULL DEFAULT 10;

-- 2. Tambahkan kolom late_minutes di tabel attendance_logs
-- Menyimpan berapa menit terlambat (NULL jika tidak terlambat)
ALTER TABLE attendance_logs 
ADD COLUMN IF NOT EXISTS late_minutes INTEGER;

-- 3. Update function submit_attendance untuk menghitung keterlambatan
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
    v_schedule_id INTEGER;
    v_schedule_start_time TIME;
    v_late_tolerance INTEGER;
    v_scan_time TIME;
    v_late_minutes INTEGER;
    v_status TEXT;
    v_current_day_of_week INTEGER;
    v_message TEXT;
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
    
    -- 6. Cek jadwal untuk menghitung keterlambatan (hanya untuk START_TEACHING)
    v_late_minutes := NULL;
    v_status := 'VALID';
    
    IF p_scan_type = 'START_TEACHING' THEN
        -- Ambil hari ini dalam timezone lokal (Asia/Jakarta)
        -- Convert ke timezone lokal dulu, baru ambil DOW
        v_current_day_of_week := EXTRACT(DOW FROM (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta'));
        -- PostgreSQL DOW: 0=Minggu, 1=Senin, ..., 6=Sabtu
        -- Kita perlu convert: 0->7, 1->1, ..., 6->6
        IF v_current_day_of_week = 0 THEN
            v_current_day_of_week := 7;
        END IF;
        
        -- Cari jadwal yang sesuai dengan hari ini, ruangan, dan guru
        SELECT id, start_time, late_tolerance_minutes
        INTO v_schedule_id, v_schedule_start_time, v_late_tolerance
        FROM schedules
        WHERE teacher_id = v_user_id
            AND room_id = v_room_id
            AND day_of_week = v_current_day_of_week
            AND is_active = TRUE
        ORDER BY start_time ASC
        LIMIT 1;
        
        -- Jika ada jadwal, hitung keterlambatan
        IF v_schedule_id IS NOT NULL THEN
            -- Gunakan waktu lokal (timezone Asia/Jakarta = WIB)
            -- Convert CURRENT_TIMESTAMP ke timezone lokal, lalu ambil TIME-nya
            v_scan_time := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta')::TIME;
            
            -- Hitung selisih waktu dalam menit
            -- EXTRACT(EPOCH FROM time_diff) mengembalikan detik, bagi 60 untuk menit
            v_late_minutes := EXTRACT(EPOCH FROM (v_scan_time - v_schedule_start_time)) / 60;
            
            -- Jika scan_time lebih awal dari start_time, set ke 0 (tidak terlambat)
            IF v_late_minutes < 0 THEN
                v_late_minutes := 0;
            END IF;
            
            -- Jika terlambat lebih dari toleransi, set status LATE
            IF v_late_minutes > v_late_tolerance THEN
                v_status := 'LATE';
            ELSE
                v_status := 'ON_TIME';
            END IF;
        END IF;
    END IF;
    
    -- 7. Insert Log (Jika Lolos)
    -- Gunakan CURRENT_TIMESTAMP yang sudah otomatis handle timezone
    -- Supabase menyimpan dalam UTC dan akan dikonversi saat query
    INSERT INTO attendance_logs (
        teacher_id, 
        room_id, 
        scan_time, 
        scan_type, 
        gps_lat, 
        gps_long, 
        status,
        distance_meters,
        late_minutes
    )
    VALUES (
        v_user_id, 
        v_room_id, 
        CURRENT_TIMESTAMP, 
        p_scan_type, 
        p_user_lat, 
        p_user_long, 
        v_status,
        v_dist_meters,
        v_late_minutes
    );
    
    -- 8. Build response message
    v_message := 'Presensi berhasil dicatat di ' || v_room_name || '!';
    
    IF v_status = 'LATE' AND v_late_minutes IS NOT NULL THEN
        v_message := v_message || ' (Terlambat ' || v_late_minutes::text || ' menit)';
    ELSIF v_status = 'ON_TIME' THEN
        v_message := v_message || ' (Tepat waktu)';
    END IF;
    
    RETURN json_build_object(
        'status', 'success',
        'message', v_message,
        'room_name', v_room_name,
        'distance_meters', v_dist_meters,
        'scan_type', p_scan_type,
        'attendance_status', v_status,
        'late_minutes', v_late_minutes
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'status', 'error',
            'message', 'Terjadi kesalahan: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_attendance TO authenticated;

-- Verifikasi perubahan
SELECT 
    'Migration completed: ' ||
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'schedules' AND column_name = 'late_tolerance_minutes'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'attendance_logs' AND column_name = 'late_minutes'
        ) THEN '✅ Success'
        ELSE '❌ Failed'
    END as migration_status;

