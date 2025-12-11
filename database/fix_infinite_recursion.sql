-- ============================================
-- FIX: Infinite Recursion dalam RLS Policy
-- ============================================
-- Error: infinite recursion detected in policy for relation "profiles"
-- 
-- Masalah: Policy admin mencoba query tabel profiles yang sama,
--          menyebabkan infinite loop.
-- 
-- Solusi: Buat function SECURITY DEFINER untuk cek role admin
-- ============================================

-- 1. Buat function untuk cek apakah user adalah admin
-- Function ini bypass RLS karena SECURITY DEFINER
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = user_id AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Hapus policies lama yang menyebabkan recursion
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- 3. Buat ulang policies tanpa recursion
-- Policy untuk user melihat profile sendiri
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Policy untuk user update profile sendiri
CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Policy untuk admin melihat semua profiles
-- Menggunakan function is_admin() yang bypass RLS
CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (is_admin(auth.uid()));

-- Policy untuk admin insert profiles
CREATE POLICY "Admins can insert profiles"
    ON profiles FOR INSERT
    WITH CHECK (is_admin(auth.uid()));

-- Policy untuk admin update semua profiles
CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (is_admin(auth.uid()));

-- 4. Fix policies untuk tabel lain juga (jika ada masalah yang sama)
-- Classrooms
DROP POLICY IF EXISTS "Admins can manage classrooms" ON classrooms;
CREATE POLICY "Admins can manage classrooms"
    ON classrooms FOR ALL
    USING (is_admin(auth.uid()));

-- Schedules
DROP POLICY IF EXISTS "Admins can manage schedules" ON schedules;
CREATE POLICY "Admins can manage schedules"
    ON schedules FOR ALL
    USING (is_admin(auth.uid()));

-- Attendance Logs
DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance_logs;
CREATE POLICY "Admins can view all attendance"
    ON attendance_logs FOR SELECT
    USING (is_admin(auth.uid()));

-- 5. Verifikasi function dibuat
SELECT 
    'Function is_admin: ' || 
    CASE WHEN EXISTS (
        SELECT FROM pg_proc 
        WHERE proname = 'is_admin'
    ) THEN '✅ Dibuat' ELSE '❌ Tidak ada' END as status;

-- 6. Test function (opsional)
-- SELECT is_admin('8d315b9c-8961-4e1d-9392-322e1edd37e8'::UUID);

-- ============================================
-- CATATAN:
-- ============================================
-- 1. Function is_admin() menggunakan SECURITY DEFINER
--    sehingga bisa bypass RLS untuk cek role
-- 2. Function ini STABLE untuk optimasi query
-- 3. Setelah menjalankan script ini, coba login lagi
-- 4. Jika masih error, pastikan profile sudah dibuat untuk user

