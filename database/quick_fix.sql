-- ============================================
-- QUICK FIX: Fix Error 500 pada Query Profiles
-- ============================================
-- Jalankan script ini di Supabase SQL Editor jika mengalami error 500
-- saat query tabel profiles

-- 1. Verifikasi tabel profiles ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles'
    ) THEN
        RAISE EXCEPTION 'Tabel profiles tidak ditemukan! Jalankan database/schema.sql terlebih dahulu.';
    END IF;
END $$;

-- 2. Pastikan RLS enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 3. Buat function helper untuk menghindari infinite recursion
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = user_id AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION is_admin TO authenticated;

-- 4. Hapus policies lama jika ada (untuk menghindari konflik)
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- 5. Buat ulang policies dengan benar (menggunakan function is_admin)
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (is_admin(auth.uid()));

CREATE POLICY "Admins can insert profiles"
    ON profiles FOR INSERT
    WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (is_admin(auth.uid()));

-- 6. Buat profile untuk user yang sudah login tapi belum punya profile
-- GANTI '8d315b9c-8961-4e1d-9392-322e1edd37e8' dengan User ID Anda
-- Dapatkan User ID dari: Authentication > Users di Supabase Dashboard

-- Uncomment baris di bawah dan ganti USER_ID_HERE dengan User ID Anda
-- INSERT INTO profiles (id, nip, full_name, role)
-- VALUES (
--   'USER_ID_HERE',
--   'ADMIN001',
--   'Nama Admin',
--   'admin'
-- )
-- ON CONFLICT (id) DO NOTHING;

-- 7. Verifikasi hasil
SELECT 
    'Tabel profiles: ' || 
    CASE WHEN EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'profiles'
    ) THEN '✅ Ada' ELSE '❌ Tidak ada' END as status
UNION ALL
SELECT 
    'RLS enabled: ' || 
    CASE WHEN (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') 
    THEN '✅ Ya' ELSE '❌ Tidak' END
UNION ALL
SELECT 
    'Policies: ' || COUNT(*)::text || ' policies'
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'profiles';

-- ============================================
-- CATATAN PENTING:
-- ============================================
-- 1. Pastikan user sudah dibuat di Authentication > Users
-- 2. Setelah user dibuat, jalankan INSERT untuk membuat profile
-- 3. Jika masih error, cek Supabase Logs untuk detail error
-- 4. Untuk testing, bisa disable RLS sementara:
--    ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
--    (JANGAN digunakan di production!)

