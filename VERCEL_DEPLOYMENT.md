# 🚀 Panduan Deploy ke Vercel - SIGAP

Panduan lengkap untuk deploy aplikasi SIGAP ke Vercel dengan environment variables.

---

## 📋 Prasyarat

1. ✅ Akun Vercel (gratis di [vercel.com](https://vercel.com))
2. ✅ Repository GitHub yang sudah berisi code SIGAP
3. ✅ Credentials Supabase (URL dan Anon Key)

---

## 🔧 Setup Environment Variables di Vercel

### **Langkah 1: Login ke Vercel Dashboard**

1. Buka [vercel.com](https://vercel.com)
2. Login dengan GitHub account Anda

### **Langkah 2: Import Project**

1. Klik **"Add New..."** > **"Project"**
2. Pilih repository GitHub yang berisi code SIGAP
3. Klik **"Import"**

### **Langkah 3: Tambahkan Environment Variables (PENTING!)**

**⚠️ WAJIB dilakukan sebelum deploy pertama kali!**

1. Di halaman project setup, scroll ke bawah ke bagian **"Environment Variables"**
2. Atau setelah project dibuat, masuk ke **Settings** > **Environment Variables**

3. **Tambahkan SUPABASE_URL:**
   - Klik **"Add New"**
   - **Name:** `SUPABASE_URL`
   - **Value:** `https://your-project-id.supabase.co` (ganti dengan URL Supabase Anda)
   - **Environment:** Centang semua (Production, Preview, Development)
   - Klik **"Save"**

4. **Tambahkan SUPABASE_ANON_KEY:**
   - Klik **"Add New"** lagi
   - **Name:** `SUPABASE_ANON_KEY`
   - **Value:** `your-anon-key-here` (ganti dengan anon key Supabase Anda)
   - **Environment:** Centang semua (Production, Preview, Development)
   - Klik **"Save"**

### **Cara Mendapatkan Credentials Supabase:**

1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Pilih project Anda
3. Klik **Settings** (icon gear) di sidebar kiri
4. Klik **API** di menu Settings
5. Copy:
   - **Project URL** → ini adalah `SUPABASE_URL`
   - **anon/public key** → ini adalah `SUPABASE_ANON_KEY`

---

## 🚀 Deploy

### **Metode 1: Deploy via Vercel Dashboard (Recommended)**

1. Setelah menambah environment variables, scroll ke atas
2. Klik **"Deploy"**
3. Vercel akan otomatis:
   - Install Flutter SDK (ini akan memakan waktu beberapa menit)
   - Run `flutter pub get`
   - Build dengan command: `flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   - Deploy folder `build/web`

4. Tunggu hingga build selesai (biasanya 5-10 menit untuk pertama kali)
5. Setelah selesai, Anda akan mendapat URL production seperti: `https://sigap-app.vercel.app`

### **Metode 2: Deploy via Vercel CLI**

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Login:**
   ```bash
   vercel login
   ```

3. **Deploy:**
   ```bash
   vercel --prod
   ```

   **Note:** Pastikan environment variables sudah ditambahkan di Vercel dashboard terlebih dahulu!

---

## 📝 File Konfigurasi

Project sudah include file `vercel.json` dengan konfigurasi yang benar:

```json
{
  "version": 2,
  "buildCommand": "flutter pub get && flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY",
  "outputDirectory": "build/web",
  "installCommand": "curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.7.2-stable.tar.xz | tar xJ && export PATH=\"$PATH:`pwd`/flutter/bin\" && flutter doctor && flutter pub get",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

**Penjelasan:**
- `buildCommand`: Build Flutter web dengan environment variables dari Vercel
- `outputDirectory`: Folder output build (`build/web`)
- `installCommand`: Install Flutter SDK dan dependencies
- `rewrites`: Redirect semua route ke `index.html` (untuk Flutter routing)

---

## ✅ Verifikasi Deploy

Setelah deploy selesai:

1. **Buka URL production** yang diberikan Vercel
2. **Test Login:**
   - Pastikan halaman login muncul
   - Test login dengan credentials yang valid
   - Pastikan tidak ada error di console browser

3. **Check Console:**
   - Buka Developer Tools (F12)
   - Check Console tab
   - Pastikan tidak ada error terkait Supabase connection

---

## 🔄 Update Environment Variables

Jika Anda perlu mengubah environment variables:

1. Masuk ke **Settings** > **Environment Variables**
2. Edit variable yang ingin diubah
3. Klik **Save**
4. **Redeploy:**
   - Masuk ke **Deployments**
   - Klik menu (3 dots) pada deployment terbaru
   - Pilih **Redeploy**

---

## 🐛 Troubleshooting

### **Error: "Supabase configuration is invalid"**

**Penyebab:** Environment variables belum ditambahkan atau salah.

**Solusi:**
1. Pastikan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` sudah ditambahkan di Vercel dashboard
2. Pastikan values sudah benar (tidak ada spasi di awal/akhir)
3. Redeploy setelah menambah/mengubah environment variables

### **Error: "Flutter command not found"**

**Penyebab:** Flutter SDK belum terinstall saat build.

**Solusi:**
- File `vercel.json` sudah include install command untuk Flutter SDK
- Pastikan `installCommand` di `vercel.json` sudah benar
- Build pertama kali akan lebih lama karena perlu download Flutter SDK

### **Build Timeout**

**Penyebab:** Build memakan waktu terlalu lama.

**Solusi:**
- Build pertama kali akan memakan waktu 5-10 menit karena perlu download Flutter SDK
- Pastikan koneksi internet stabil
- Jika masih timeout, coba deploy ulang

### **404 Error di Route Tertentu**

**Penyebab:** Routing Flutter tidak ter-handle dengan benar.

**Solusi:**
- Pastikan `rewrites` di `vercel.json` sudah benar
- Semua route harus redirect ke `/index.html`

---

## 📚 Referensi

- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Supabase Documentation](https://supabase.com/docs)

---

## 💡 Tips

1. **Gunakan Preview Deployments:**
   - Setiap push ke branch akan trigger preview deployment
   - Perfect untuk testing sebelum merge ke production

2. **Monitor Build Logs:**
   - Di Vercel dashboard, klik deployment untuk melihat build logs
   - Berguna untuk debugging jika ada error

3. **Custom Domain:**
   - Setelah deploy berhasil, Anda bisa add custom domain
   - Masuk ke **Settings** > **Domains**
   - Follow instruksi untuk setup DNS

---

**Selamat! Aplikasi SIGAP Anda sudah ter-deploy di Vercel! 🎉**

