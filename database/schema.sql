-- ============================================
-- SIGAP - Database Schema for Supabase
-- Sistem Informasi Guru & Absensi Pegawai
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. Tabel profiles (Data Guru)
-- Terhubung dengan auth.users Supabase
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nip TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'guru' CHECK (role IN ('admin', 'guru')),
    base_salary BIGINT DEFAULT 0,
    hourly_rate BIGINT DEFAULT 0,
    presence_rate BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_profiles_nip ON profiles(nip);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- ============================================
-- 2. Tabel classrooms (Titik Scan QR)
-- Menyimpan data lokasi valid untuk scan
-- ============================================
CREATE TABLE IF NOT EXISTS classrooms (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    qr_secret TEXT UNIQUE NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meter INTEGER NOT NULL DEFAULT 20,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_classrooms_qr_secret ON classrooms(qr_secret);
CREATE INDEX IF NOT EXISTS idx_classrooms_active ON classrooms(is_active);

-- ============================================
-- 3. Tabel schedules (Jadwal Pelajaran)
-- Digunakan untuk memvalidasi apakah guru scan di jam yang tepat
-- ============================================
CREATE TABLE IF NOT EXISTS schedules (
    id SERIAL PRIMARY KEY,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    room_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Senin, 7=Minggu
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    subject TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_schedules_teacher ON schedules(teacher_id);
CREATE INDEX IF NOT EXISTS idx_schedules_room ON schedules(room_id);
CREATE INDEX IF NOT EXISTS idx_schedules_day ON schedules(day_of_week);

-- ============================================
-- 4. Tabel attendance_logs (Rekap Kehadiran)
-- Tabel transaksi utama untuk presensi
-- ============================================
CREATE TABLE IF NOT EXISTS attendance_logs (
    id BIGSERIAL PRIMARY KEY,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    room_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    scan_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    scan_type TEXT NOT NULL CHECK (scan_type IN ('CHECK_IN_SCHOOL', 'START_TEACHING', 'END_TEACHING')),
    status TEXT NOT NULL DEFAULT 'ON_TIME' CHECK (status IN ('ON_TIME', 'LATE', 'VALID')),
    gps_lat DOUBLE PRECISION NOT NULL,
    gps_long DOUBLE PRECISION NOT NULL,
    distance_meters DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_attendance_teacher ON attendance_logs(teacher_id);
CREATE INDEX IF NOT EXISTS idx_attendance_room ON attendance_logs(room_id);
CREATE INDEX IF NOT EXISTS idx_attendance_scan_time ON attendance_logs(scan_time);
CREATE INDEX IF NOT EXISTS idx_attendance_teacher_date ON attendance_logs(teacher_id, scan_time);

-- ============================================
-- 5. Helper Function untuk RLS (Mencegah Infinite Recursion)
-- ============================================

-- Function untuk cek apakah user adalah admin
-- Menggunakan SECURITY DEFINER untuk bypass RLS
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = user_id AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;

-- ============================================
-- 6. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Policy untuk admin menggunakan function is_admin() untuk menghindari recursion
CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (is_admin(auth.uid()));

CREATE POLICY "Admins can insert profiles"
    ON profiles FOR INSERT
    WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (is_admin(auth.uid()));

-- Classrooms Policies
CREATE POLICY "Everyone can view active classrooms"
    ON classrooms FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage classrooms"
    ON classrooms FOR ALL
    USING (is_admin(auth.uid()));

-- Schedules Policies
CREATE POLICY "Teachers can view their own schedules"
    ON schedules FOR SELECT
    USING (
        teacher_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can manage schedules"
    ON schedules FOR ALL
    USING (is_admin(auth.uid()));

-- Attendance Logs Policies
CREATE POLICY "Teachers can view their own attendance"
    ON attendance_logs FOR SELECT
    USING (
        teacher_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Teachers can insert their own attendance"
    ON attendance_logs FOR INSERT
    WITH CHECK (teacher_id = auth.uid());

CREATE POLICY "Admins can view all attendance"
    ON attendance_logs FOR SELECT
    USING (is_admin(auth.uid()));

-- ============================================
-- 6. Functions & Triggers
-- ============================================

-- Function untuk update updated_at otomatis
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers untuk update updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classrooms_updated_at
    BEFORE UPDATE ON classrooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at
    BEFORE UPDATE ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. Function untuk Submit Attendance (RPC)
-- Validasi Geofencing & Anti-Fraud
-- ============================================
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
    -- (Prevent duplicate scans)
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
    
    -- 6. Tentukan status (ON_TIME atau LATE)
    -- Untuk sekarang, kita set sebagai VALID. Bisa ditambahkan logika pengecekan jadwal
    
    -- 7. Insert Log (Jika Lolos)
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_attendance TO authenticated;

-- ============================================
-- 8. Function untuk Get Today's Attendance Stats (Admin)
-- ============================================
CREATE OR REPLACE FUNCTION get_today_attendance_stats()
RETURNS JSON AS $$
DECLARE
    v_total_teachers INTEGER;
    v_present_count INTEGER;
    v_absent_count INTEGER;
BEGIN
    -- Total teachers
    SELECT COUNT(*) INTO v_total_teachers
    FROM profiles
    WHERE role = 'guru';
    
    -- Present today (yang sudah check in)
    SELECT COUNT(DISTINCT teacher_id) INTO v_present_count
    FROM attendance_logs
    WHERE DATE(scan_time) = CURRENT_DATE
        AND scan_type = 'CHECK_IN_SCHOOL';
    
    v_absent_count := v_total_teachers - v_present_count;
    
    RETURN json_build_object(
        'total_teachers', v_total_teachers,
        'present', v_present_count,
        'absent', v_absent_count,
        'date', CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_today_attendance_stats TO authenticated;

-- ============================================
-- 9. Sample Data (Optional - untuk testing)
-- ============================================

-- Insert sample classroom (setelah membuat profile admin)
-- INSERT INTO classrooms (name, qr_secret, latitude, longitude, radius_meter)
-- VALUES 
--     ('Gerbang Utama', 'GATE-MAIN-001', -6.2088, 106.8456, 20),
--     ('Kelas 7A', 'ROOM-7A-001', -6.2089, 106.8457, 15),
--     ('Lab Komputer', 'LAB-COMP-001', -6.2090, 106.8458, 15);

-- ============================================
-- END OF SCHEMA
-- ============================================

