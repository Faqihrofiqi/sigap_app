# 🔧 Troubleshooting Guide - SIGAP

Panduan untuk mengatasi masalah umum yang terjadi saat setup dan penggunaan aplikasi SIGAP.

## ❌ Error: Infinite Recursion dalam RLS Policy

### Gejala
```
PostgrestException: infinite recursion detected in policy for relation "profiles"
```

### Penyebab
Policy admin mencoba query tabel `profiles` yang sama, menyebabkan infinite loop.

### Solusi Cepat
**Jalankan script `database/fix_infinite_recursion.sql` di Supabase SQL Editor**

Script ini akan:
1. Membuat function `is_admin()` yang bypass RLS
2. Memperbaiki semua policies yang menyebabkan recursion
3. Menggunakan function tersebut untuk cek role admin

---

## ❌ Error 500: Internal Server Error saat Query Profiles

### Gejala
```
GET .../rest/v1/profiles?select=*&id=eq.xxx 500 (Internal Server Error)
```

### Penyebab
Error 500 biasanya terjadi karena:
1. **Infinite recursion dalam RLS policy** - Policy admin query tabel yang sama
2. **Database schema belum dijalankan** - Tabel `profiles` belum dibuat
3. **RLS policies terlalu ketat** - Row Level Security memblokir query
4. **Profile belum dibuat** - User ada di `auth.users` tapi tidak ada di tabel `profiles`
5. **Foreign key constraint** - User ID tidak ada di `auth.users`

### Solusi

#### 1. Verifikasi Database Schema Sudah Dijalankan

1. Buka Supabase Dashboard
2. Klik **Table Editor** di sidebar kiri
3. Pastikan tabel berikut ada:
   - ✅ `profiles`
   - ✅ `classrooms`
   - ✅ `schedules`
   - ✅ `attendance_logs`

**Jika tabel tidak ada:**
1. Buka **SQL Editor** di Supabase
2. Copy semua isi file `database/schema.sql`
3. Paste dan jalankan query
4. Pastikan tidak ada error

#### 2. Fix Infinite Recursion (PENTING!)

**Jika error "infinite recursion detected":**

1. Buka Supabase Dashboard > **SQL Editor**
2. Copy dan jalankan isi file `database/fix_infinite_recursion.sql`
3. Script akan membuat function `is_admin()` dan memperbaiki policies

**Atau jalankan manual:**

```sql
-- Buat function helper
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

-- Hapus policies lama
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- Buat ulang dengan function
CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (is_admin(auth.uid()));

CREATE POLICY "Admins can insert profiles"
    ON profiles FOR INSERT
    WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (is_admin(auth.uid()));
```

#### 3. Verifikasi RLS Policies

1. Buka Supabase Dashboard > **Authentication** > **Policies**
2. Atau buka **SQL Editor** dan jalankan:

```sql
-- Cek apakah RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'profiles';

-- Cek function is_admin ada
SELECT proname FROM pg_proc WHERE proname = 'is_admin';
```

#### 3. Buat Profile untuk User yang Sudah Login

Jika user sudah ada di `auth.users` tapi belum ada profile:

1. Buka Supabase Dashboard > **Authentication** > **Users**
2. Copy **User ID** dari user yang ingin dibuatkan profile
3. Buka **SQL Editor** dan jalankan:

```sql
-- Ganti USER_ID_HERE dengan User ID yang dicopy
INSERT INTO profiles (id, nip, full_name, role)
VALUES (
  'USER_ID_HERE',
  'ADMIN001',  -- atau 'GURU001' untuk guru
  'Nama User',
  'admin'      -- atau 'guru'
);
```

#### 4. Verifikasi User Ada di auth.users

Jalankan query ini di SQL Editor:

```sql
-- Cek apakah user ada
SELECT id, email, created_at 
FROM auth.users 
WHERE id = '8d315b9c-8961-4e1d-9392-322e1edd37e8';
```

**Jika user tidak ada:**
1. Buat user baru di **Authentication** > **Users** > **Add User**
2. Setelah user dibuat, buat profile seperti langkah 3 di atas

---

## ❌ Error: "Supabase belum diinisialisasi"

### Solusi
1. Pastikan credentials di `lib/main.dart` sudah diisi
2. Restart aplikasi setelah mengubah credentials
3. Cek console untuk error saat inisialisasi

---

## ❌ Error: "Email atau password salah"

### Solusi
1. Verifikasi user ada di Supabase Authentication
2. Verifikasi profile sudah dibuat di tabel `profiles`
3. Pastikan role sudah sesuai (admin/guru)
4. Coba reset password di Supabase Dashboard

---

## ❌ Error: "QR Code tidak dikenali"

### Solusi
1. Pastikan ruangan sudah di-insert di tabel `classrooms`
2. Pastikan `qr_secret` di database sama dengan isi QR Code
3. Pastikan `is_active = true` untuk ruangan tersebut

**Cek di SQL Editor:**
```sql
SELECT * FROM classrooms WHERE qr_secret = 'GATE-MAIN-001';
```

---

## ❌ Error: "Lokasi terlalu jauh"

### Solusi
1. Pastikan GPS aktif dan akurat
2. Pastikan koordinat ruangan di database sesuai dengan lokasi fisik
3. Perbesar `radius_meter` jika perlu (minimal 15-20 meter)

**Update radius:**
```sql
UPDATE classrooms 
SET radius_meter = 30 
WHERE id = 1;
```

---

## ❌ Camera tidak berfungsi

### Solusi
1. Berikan permission camera saat diminta
2. Restart aplikasi setelah memberikan permission
3. Untuk Android: Cek Settings > Apps > SIGAP > Permissions
4. Untuk iOS: Cek Settings > SIGAP > Camera

---

## ❌ Error: "Mock Location terdeteksi"

### Solusi
1. Matikan aplikasi Mock Location di HP
2. Restart aplikasi
3. Pastikan GPS asli aktif

---

## ❌ Tabel tidak muncul di Table Editor

### Solusi
1. Pastikan schema sudah dijalankan di SQL Editor
2. Refresh halaman Table Editor
3. Cek apakah ada error saat menjalankan schema

**Verifikasi tabel ada:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

---

## ❌ Function submit_attendance tidak ditemukan

### Solusi
1. Pastikan function sudah dibuat di database
2. Jalankan bagian function dari `database/schema.sql` lagi

**Verifikasi function ada:**
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'submit_attendance';
```

---

## 🔍 Debug Tips

### 1. Cek Logs di Supabase
1. Buka Supabase Dashboard > **Logs** > **Postgres Logs**
2. Lihat error messages yang muncul

### 2. Test Query Langsung
Jalankan query di SQL Editor untuk test:

```sql
-- Test query profiles
SELECT * FROM profiles WHERE id = 'YOUR_USER_ID';

-- Test RLS
SET ROLE authenticated;
SELECT * FROM profiles;
```

### 3. Cek Browser Console
Buka Developer Tools (F12) dan lihat:
- Network tab untuk melihat request/response
- Console tab untuk melihat error messages

### 4. Enable Debug Mode
Di `lib/main.dart`, pastikan `kDebugMode` aktif untuk melihat log:

```dart
if (kDebugMode) {
  print('Debug info here');
}
```

---

## 📞 Masih Bermasalah?

1. Cek Supabase Dashboard > **Logs** untuk error detail
2. Cek browser console untuk error JavaScript
3. Pastikan semua langkah di `SETUP.md` sudah dilakukan
4. Buat issue di repository dengan detail error

---

## ✅ Checklist Setup

Pastikan semua ini sudah dilakukan:

- [ ] Database schema dijalankan di SQL Editor
- [ ] User admin dibuat di Authentication
- [ ] Profile admin di-insert di tabel profiles
- [ ] Credentials Supabase diisi di `lib/main.dart`
- [ ] RLS policies sudah dibuat
- [ ] Function `submit_attendance` sudah dibuat
- [ ] Function `get_today_attendance_stats` sudah dibuat
- [ ] Test login berhasil
- [ ] Test query profiles berhasil

---

**Last Updated**: 2024

