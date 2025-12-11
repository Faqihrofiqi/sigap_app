# 🚨 Panduan Mengatasi Limit Supabase

## Jenis Limit di Supabase Free Tier

### 1. **API Requests** (500,000/month)
- Setiap query ke database = 1 request
- Setiap RPC call = 1 request
- Setiap auth operation = 1 request

### 2. **Database Size** (500 MB)
- Total ukuran semua tabel dan data

### 3. **Storage** (1 GB)
- File uploads (jika ada)

### 4. **Bandwidth** (5 GB/month)
- Data transfer keluar dari Supabase

### 5. **Auth Users** (50,000)
- Jumlah user yang bisa dibuat

## ✅ Optimasi yang Sudah Diterapkan

### 1. **Caching System**
Aplikasi sekarang menggunakan caching untuk mengurangi request:

- **User Profile**: Cache 10 menit
- **Today Stats**: Cache 2 menit
- **All Teachers**: Cache 5 menit
- **All Classrooms**: Cache 5 menit
- **All Schedules**: Cache 5 menit

**Cara Kerja:**
- Data pertama kali diambil dari Supabase
- Data disimpan di cache lokal (SharedPreferences)
- Request berikutnya menggunakan cache jika masih valid
- Cache otomatis expired setelah waktu tertentu
- Cache di-clear otomatis setelah CRUD operations

### 2. **Parallel Loading**
Dashboard admin menggunakan `Future.wait()` untuk load data secara paralel, mengurangi waktu loading.

### 3. **Query Optimization**
- Limit hasil query (max 100 records untuk attendance history)
- Hanya select kolom yang diperlukan
- Menggunakan index yang sudah ada di database

## 🔧 Tips Tambahan untuk Mengurangi Limit

### 1. **Kurangi Refresh Manual**
- Jangan terlalu sering klik tombol refresh
- Gunakan pull-to-refresh dengan bijak
- Cache sudah otomatis refresh setelah expired

### 2. **Optimasi Query di Database**
Pastikan index sudah dibuat untuk kolom yang sering di-query:

```sql
-- Index untuk attendance_logs
CREATE INDEX IF NOT EXISTS idx_attendance_teacher_date 
ON attendance_logs(teacher_id, scan_time);

CREATE INDEX IF NOT EXISTS idx_attendance_scan_time 
ON attendance_logs(scan_time DESC);

-- Index untuk schedules
CREATE INDEX IF NOT EXISTS idx_schedules_teacher_day 
ON schedules(teacher_id, day_of_week, is_active);
```

### 3. **Gunakan Pagination**
Untuk data yang banyak, gunakan pagination:

```dart
// Contoh pagination
final response = await client
    .from('attendance_logs')
    .select()
    .order('scan_time', ascending: false)
    .range(0, 49) // 50 records per page
    .limit(50);
```

### 4. **Hapus Data Lama**
Bersihkan data attendance_logs yang sudah lama (misal > 1 tahun):

```sql
-- Hapus data lebih dari 1 tahun
DELETE FROM attendance_logs 
WHERE scan_time < NOW() - INTERVAL '1 year';
```

### 5. **Monitor Usage**
Cek penggunaan di Supabase Dashboard:
1. Buka **Settings** > **Usage**
2. Monitor:
   - API Requests
   - Database Size
   - Bandwidth

## 🚀 Upgrade ke Pro Tier (Opsional)

Jika limit masih kurang, pertimbangkan upgrade:

**Pro Tier ($25/month):**
- 5M API requests/month
- 8 GB database
- 100 GB bandwidth
- Unlimited auth users

## 📊 Monitoring Cache

Untuk melihat cache yang aktif, tambahkan di debug mode:

```dart
// Di CacheService.getCache()
if (kDebugMode) {
  print('Cache hit: $key');
}
```

## ⚠️ Catatan Penting

1. **Cache tidak real-time**: Data di cache mungkin tidak selalu terbaru
2. **Cache auto-clear**: Setelah CRUD operations, cache terkait otomatis di-clear
3. **Manual clear**: Bisa clear cache manual dengan `SupabaseService.clearAllCache()`

## 🔄 Force Refresh (Skip Cache)

Jika perlu data terbaru, gunakan parameter `useCache: false`:

```dart
// Force refresh tanpa cache
final stats = await SupabaseService.getTodayAttendanceStats(useCache: false);
final teachers = await SupabaseService.getAllTeachers(useCache: false);
```

## 📝 Best Practices

1. ✅ Gunakan cache untuk data yang jarang berubah (teachers, classrooms)
2. ✅ Cache pendek untuk data yang sering berubah (stats, attendance)
3. ✅ Clear cache setelah CRUD operations
4. ✅ Monitor usage di Supabase Dashboard
5. ✅ Hapus data lama secara berkala
6. ❌ Jangan terlalu sering refresh manual
7. ❌ Jangan query semua data tanpa limit
8. ❌ Jangan query data yang tidak diperlukan

## 🆘 Jika Masih Terkena Limit

1. **Cek Usage Dashboard**: Lihat apa yang paling banyak digunakan
2. **Optimasi Query**: Pastikan query efisien
3. **Hapus Data Lama**: Bersihkan data yang tidak diperlukan
4. **Upgrade Tier**: Pertimbangkan upgrade jika memang perlu
5. **Contact Support**: Hubungi Supabase support untuk bantuan

