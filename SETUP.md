# 🚀 Quick Setup Guide - SIGAP

Panduan cepat untuk setup aplikasi SIGAP dari awal.

## Step 1: Install Dependencies

```bash
flutter pub get
```

## Step 2: Setup Supabase

### 2.1 Buat Project Supabase
1. Kunjungi [supabase.com](https://supabase.com)
2. Buat akun (gratis)
3. Klik "New Project"
4. Isi nama project dan password database
5. Pilih region terdekat (Singapore recommended untuk Indonesia)
6. Tunggu project selesai dibuat (2-3 menit)

### 2.2 Dapatkan Credentials
1. Di Supabase Dashboard, klik **Settings** (icon gear) di sidebar kiri
2. Klik **API** di menu Settings
3. Copy **Project URL** dan **anon/public key**
4. Simpan kedua nilai ini untuk digunakan di langkah berikutnya

### 2.3 Setup Database Schema
1. Di Supabase Dashboard, klik **SQL Editor** di sidebar kiri
2. Klik **New Query**
3. Buka file `database/schema.sql` di project ini
4. Copy semua isi file tersebut
5. Paste ke SQL Editor di Supabase
6. Klik **Run** (atau tekan Ctrl+Enter)
7. Pastikan tidak ada error (harus muncul "Success. No rows returned")

### 2.4 Setup Authentication
1. Di Supabase Dashboard, klik **Authentication** > **Providers**
2. Pastikan **Email** provider sudah enabled
3. (Opsional) Atur email templates untuk reset password

## Step 3: Konfigurasi Flutter App

### 3.1 Setup Environment Variables
1. Copy file `.env.example` ke `.env`:
   ```bash
   cp .env.example .env
   ```
   
   Atau buat file `.env` baru di root project.

2. Buka file `.env` dan isi dengan credentials dari Step 2.2:
   ```env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **PENTING**: File `.env` sudah ada di `.gitignore`, jadi tidak akan ter-commit ke repository. Ini untuk keamanan.

### 3.2 Install Dependencies
```bash
flutter pub get
```

## Step 4: Buat User Admin Pertama

### 4.1 Buat User di Supabase Auth
1. Di Supabase Dashboard, klik **Authentication** > **Users**
2. Klik tombol **Add User** > **Create new user**
3. Isi:
   - **Email**: email admin Anda (contoh: admin@sekolah.com)
   - **Password**: password yang kuat
   - **Auto Confirm User**: ✅ Centang (agar langsung bisa login)
4. Klik **Create User**
5. **Copy User ID** yang muncul (UUID format)

### 4.2 Insert Profile Admin
1. Klik **SQL Editor** di Supabase
2. Jalankan query berikut (ganti `USER_ID_HERE` dengan User ID dari langkah 4.1):

```sql
INSERT INTO profiles (id, nip, full_name, role)
VALUES (
  '8d315b9c-8961-4e1d-9392-322e1edd37e8',
  'ADMIN001',
  'Nama Admin Anda',
  'admin'
);
```

3. Klik **Run**
4. Pastikan muncul "Success. 1 row inserted"

## Step 5: Buat Data Sample (Opsional)

### 5.1 Buat Ruangan Sample
Jalankan query berikut di SQL Editor:

```sql
INSERT INTO classrooms (name, qr_secret, latitude, longitude, radius_meter, description)
VALUES 
  ('Gerbang Utama', 'GATE-MAIN-001', -6.2088, 106.8456, 20, 'Pintu masuk utama sekolah'),
  ('Kelas 7A', 'ROOM-7A-001', -6.2089, 106.8457, 15, 'Ruang kelas 7A'),
  ('Lab Komputer', 'LAB-COMP-001', -6.2090, 106.8458, 15, 'Laboratorium komputer');
```

**Catatan**: Ganti koordinat latitude/longitude dengan koordinat lokasi sekolah Anda. 
- Gunakan Google Maps untuk mendapatkan koordinat
- Klik kanan di lokasi > "What's here?" > Copy koordinat

### 5.2 Buat User Guru Sample
1. Buat user baru di Authentication (sama seperti Step 4.1)
2. Copy User ID
3. Jalankan query (ganti `USER_ID_HERE`):

```sql
INSERT INTO profiles (id, nip, full_name, role, presence_rate, hourly_rate)
VALUES (
  '1a582a60-054b-431a-bcc9-f7574b56c188',
  'GURU001',
  'Nama Guru',
  'guru',
  50000,  -- Insentif kehadiran per hari (Rp 50.000)
  50000   -- Insentif per jam mengajar (Rp 50.000)
);
```

## Step 6: Test Aplikasi

### 6.1 Run Aplikasi
```bash
# Android
flutter run

# iOS (Mac only)
flutter run

# Web
flutter run -d chrome
```

### 6.2 Test Login
1. Buka aplikasi
2. Login dengan email dan password admin yang dibuat di Step 4.1
3. Pastikan masuk ke Dashboard Admin

### 6.3 Test QR Code (Mobile)
1. Login sebagai guru
2. Klik tombol "Scan QR"
3. Arahkan kamera ke QR Code yang di-generate dari Admin Dashboard
4. Pastikan presensi berhasil

## Step 7: Generate QR Code untuk Ruangan

1. Login sebagai Admin
2. Buka menu **Ruangan**
3. Klik icon QR Code pada ruangan yang ingin di-generate
4. Screenshot atau download QR Code
5. Cetak dan tempel di lokasi fisik ruangan

## Troubleshooting

### Error: "Supabase belum diinisialisasi"
- Pastikan sudah mengisi credentials di `lib/main.dart`
- Restart aplikasi setelah mengubah credentials

### Error: "Email atau password salah"
- Pastikan user sudah dibuat di Supabase Authentication
- Pastikan profile sudah di-insert di tabel `profiles`
- Pastikan role sudah sesuai (admin/guru)

### Error: "QR Code tidak dikenali"
- Pastikan ruangan sudah di-insert di tabel `classrooms`
- Pastikan `qr_secret` di database sama dengan isi QR Code

### Error: "Lokasi terlalu jauh"
- Pastikan GPS aktif
- Pastikan koordinat ruangan di database sesuai dengan lokasi fisik
- Pastikan radius_meter cukup besar (minimal 15-20 meter)

### Camera tidak berfungsi
- Berikan permission camera saat diminta
- Restart aplikasi setelah memberikan permission
- Untuk Android: Cek Settings > Apps > SIGAP > Permissions

## Next Steps

1. ✅ Setup selesai!
2. Buat user guru lainnya
3. Buat ruangan sesuai kebutuhan
4. Setup jadwal pelajaran
5. Deploy ke production

## Support

Jika mengalami masalah, buat issue di repository atau hubungi developer.

---

**Tips:**
- Simpan credentials Supabase dengan aman
- Jangan commit file `lib/main.dart` dengan credentials ke repository public
- Backup database secara berkala
- Test semua fitur sebelum deploy ke production

