# SIGAP - Sistem Informasi Guru & Absensi Pegawai

Aplikasi mobile dan web untuk monitoring kehadiran guru dengan sistem QR Code dan validasi geolokasi untuk mencegah kecurangan.

## 🚀 Fitur Utama

### Untuk Guru (Mobile App)
- ✅ Login dengan email dan password
- ✅ Dashboard dengan status kehadiran hari ini
- ✅ Tampilan jadwal mengajar hari ini
- ✅ Scan QR Code untuk presensi dengan validasi geolokasi
- ✅ Riwayat kehadiran bulanan
- ✅ Estimasi insentif

### Untuk Admin/Kepsek (Web Dashboard)
- ✅ Dashboard dengan statistik real-time
- ✅ Monitoring kehadiran guru hari ini
- ✅ Manajemen data guru (tambah/edit)
- ✅ Manajemen ruangan dan QR Code generator
- ✅ Manajemen jadwal pelajaran
- ✅ Laporan kehadiran dengan filter periode
- ✅ Export ke Excel (coming soon)

## 🛡️ Fitur Keamanan Anti-Fraud

1. **Geofencing**: Validasi lokasi GPS saat scan QR Code
2. **Mock Location Detection**: Deteksi dan blokir aplikasi Mock Location
3. **Server Time Validation**: Waktu presensi menggunakan waktu server, bukan waktu HP
4. **QR Code Validation**: Validasi QR Code di backend Supabase
5. **Duplicate Prevention**: Mencegah scan ganda dalam satu hari

## 📋 Prasyarat

- Flutter SDK 3.7.2 atau lebih baru
- Dart SDK terbaru
- Akun Supabase (gratis di [supabase.com](https://supabase.com))
- Android Studio / Xcode (untuk build mobile)
- Node.js (opsional, untuk development)

## 🔧 Instalasi & Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd sigap_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Supabase

#### a. Buat Project di Supabase
1. Daftar/login di [supabase.com](https://supabase.com)
2. Buat project baru
3. Catat **Project URL** dan **Anon Key** dari Settings > API

#### b. Setup Database
1. Buka Supabase Dashboard > SQL Editor
2. Copy dan paste isi file `database/schema.sql`
3. Jalankan query untuk membuat tabel dan fungsi

#### c. Konfigurasi Flutter App
1. Buka file `lib/main.dart`
2. Ganti `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` dengan credentials Anda:

```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'your-anon-key-here';
```

### 4. Setup Permissions

#### Android
File `android/app/src/main/AndroidManifest.xml` sudah dikonfigurasi dengan permissions yang diperlukan:
- Camera
- Location (Fine & Coarse)

#### iOS
File `ios/Runner/Info.plist` sudah dikonfigurasi dengan usage descriptions.

### 5. Run Aplikasi

```bash
# Mobile (Android/iOS)
flutter run

# Web
flutter run -d chrome
```

## 📱 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── core/
│   ├── constants.dart        # Konstanta aplikasi
│   └── supabase_client.dart  # Supabase service
├── models/
│   ├── user_model.dart       # Model data user/guru
│   ├── classroom_model.dart  # Model data ruangan
│   ├── schedule_model.dart   # Model data jadwal
│   └── attendance_model.dart # Model data kehadiran
├── screens/
│   ├── auth/
│   │   └── login_screen.dart # Halaman login
│   ├── teacher/
│   │   ├── teacher_dashboard.dart    # Dashboard guru
│   │   ├── qr_scanner_screen.dart     # Halaman scan QR
│   │   └── attendance_history_screen.dart # Riwayat kehadiran
│   └── admin/
│       ├── admin_dashboard.dart       # Dashboard admin
│       ├── manage_teachers_screen.dart # Manajemen guru
│       ├── manage_classrooms_screen.dart # Manajemen ruangan
│       ├── manage_schedules_screen.dart  # Manajemen jadwal
│       └── reports_screen.dart          # Laporan
└── widgets/
    ├── qr_scanner_view.dart  # Widget QR scanner
    └── location_checker.dart # Widget validasi lokasi
```

## 🗄️ Database Schema

### Tabel `profiles`
Data guru/admin yang terhubung dengan `auth.users`

### Tabel `classrooms`
Data ruangan/titik scan QR Code dengan koordinat GPS

### Tabel `schedules`
Jadwal pelajaran untuk validasi waktu presensi

### Tabel `attendance_logs`
Log transaksi presensi dengan data GPS dan timestamp

## 🔐 Setup User Pertama (Admin)

Setelah database setup, buat user admin pertama:

1. Buka Supabase Dashboard > Authentication > Users
2. Klik "Add User" > "Create new user"
3. Masukkan email dan password
4. Setelah user dibuat, buka SQL Editor dan jalankan:

```sql
-- Ganti 'user-id-here' dengan ID user yang baru dibuat
-- Ganti dengan data admin Anda
INSERT INTO profiles (id, nip, full_name, role)
VALUES (
  'user-id-here',
  'ADMIN001',
  'Nama Admin',
  'admin'
);
```

## 📝 Cara Menggunakan

### Untuk Guru:
1. Login dengan email dan password
2. Lihat dashboard untuk status kehadiran hari ini
3. Klik tombol "Scan QR" untuk melakukan presensi
4. Arahkan kamera ke QR Code di ruangan
5. Pastikan GPS aktif dan lokasi sesuai
6. Presensi akan tercatat otomatis

### Untuk Admin:
1. Login dengan akun admin
2. Dashboard menampilkan statistik real-time
3. Kelola data guru, ruangan, dan jadwal
4. Generate QR Code untuk ruangan baru
5. Lihat laporan kehadiran dengan filter periode

## 🎯 Generate QR Code untuk Ruangan

1. Login sebagai Admin
2. Buka menu "Ruangan"
3. Tambah ruangan baru dengan koordinat GPS
4. Klik icon QR Code untuk melihat QR
5. Screenshot atau download QR Code
6. Cetak dan tempel di lokasi yang sesuai

## 🧪 Testing

```bash
# Run tests
flutter test

# Run dengan coverage
flutter test --coverage
```

## 📦 Build untuk Production

### Android
```bash
flutter build apk --release
# atau
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🐛 Troubleshooting

### Error: "Supabase belum diinisialisasi"
- Pastikan Anda sudah mengisi Supabase URL dan Anon Key di `lib/main.dart`

### Error: "QR Code tidak dikenali"
- Pastikan QR Code sudah terdaftar di tabel `classrooms`
- Pastikan `qr_secret` di database sesuai dengan isi QR Code

### Error: "Lokasi terlalu jauh"
- Pastikan GPS aktif dan akurat
- Pastikan Anda berada dalam radius yang ditentukan
- Cek koordinat ruangan di database

### Error: "Mock Location terdeteksi"
- Fitur ini telah dihapus karena masalah kompatibilitas
- Keamanan tetap terjaga melalui backend geofencing validation
- Server-side validation mencegah location spoofing

### Camera tidak berfungsi
- Pastikan permission camera sudah diberikan
- Restart aplikasi setelah memberikan permission

## 📚 Dependencies Utama

- `supabase_flutter`: Backend & Database
- `mobile_scanner`: QR Code Scanner
- `geolocator`: GPS Location
- `permission_handler`: Permission Management
- ~~`trust_location`: Mock Location Detection~~ (Dihapus - tidak kompatibel)
- `qr_flutter`: QR Code Generation
- `intl`: Date/Time Formatting

## 🤝 Kontribusi

Kontribusi sangat diterima! Silakan buat issue atau pull request.

## 📄 Lisensi

Project ini menggunakan lisensi MIT.

## 👨‍💻 Developer

Dibuat dengan ❤️ menggunakan Flutter & Supabase

## 📞 Support

Untuk pertanyaan atau bantuan, silakan buat issue di repository ini.

---

**Catatan Penting:**
- Pastikan untuk tidak commit file `lib/main.dart` dengan credentials Supabase ke repository public
- Gunakan environment variables atau file konfigurasi terpisah untuk production
- Backup database secara berkala
- Test semua fitur sebelum deploy ke production
