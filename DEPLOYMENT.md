# 📦 Panduan Deploy Website SIGAP

Dokumen ini menjelaskan langkah-langkah untuk deploy aplikasi SIGAP ke production.

---

## 📋 Daftar Isi

1. [Persiapan Sebelum Deploy](#persiapan-sebelum-deploy)
2. [Build Aplikasi untuk Web](#build-aplikasi-untuk-web)
3. [Deploy ke Vercel](#deploy-ke-vercel)
4. [Deploy ke Netlify](#deploy-ke-netlify)
5. [Deploy ke Firebase Hosting](#deploy-ke-firebase-hosting)
6. [Deploy ke GitHub Pages](#deploy-ke-github-pages)
7. [Konfigurasi Environment Variables](#konfigurasi-environment-variables)
8. [Setup Custom Domain](#setup-custom-domain)
9. [Testing Setelah Deploy](#testing-setelah-deploy)
10. [Troubleshooting](#troubleshooting)

---

## 🚀 Persiapan Sebelum Deploy

### 1. **Persiapan Environment Variables**

Pastikan Anda memiliki:
- ✅ Supabase URL
- ✅ Supabase Anon Key
- ✅ Supabase Service Role Key (untuk edge functions)

### 2. **Update Konfigurasi di Code**

Pastikan file `lib/main.dart` sudah menggunakan environment variables atau hardcoded credentials yang benar:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

**⚠️ PENTING:** Untuk production, gunakan environment variables, jangan hardcode credentials!

### 3. **Install Dependencies**

```bash
flutter pub get
```

### 4. **Test Build Lokal**

```bash
flutter build web
```

Pastikan build berhasil tanpa error.

---

## 🔨 Build Aplikasi untuk Web

### **Build untuk Production**

```bash
# Build dengan optimasi untuk production
flutter build web --release --web-renderer canvaskit

# Atau untuk ukuran lebih kecil (tapi mungkin ada kompatibilitas issue)
flutter build web --release --web-renderer html
```

**Penjelasan:**
- `--release`: Build mode production (optimized)
- `--web-renderer canvaskit`: Renderer yang lebih stabil (ukuran lebih besar)
- `--web-renderer html`: Renderer yang lebih kecil (ukuran lebih kecil, tapi mungkin ada issue)

### **Output Build**

Build akan menghasilkan folder `build/web/` yang berisi:
- `index.html`
- `main.dart.js`
- `assets/`
- `canvaskit/` (jika menggunakan canvaskit)

---

## 🌐 Deploy ke Vercel

Vercel adalah platform yang sangat mudah untuk deploy Flutter web apps.

### **Metode 1: Deploy via Vercel CLI**

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Login ke Vercel**
   ```bash
   vercel login
   ```

3. **Buat file `vercel.json` di root project**
   ```json
   {
     "version": 2,
     "builds": [
       {
         "src": "build/web/**",
         "use": "@vercel/static"
       }
     ],
     "routes": [
       {
         "src": "/(.*)",
         "dest": "/build/web/$1"
       }
     ],
     "rewrites": [
       {
         "source": "/(.*)",
         "destination": "/index.html"
       }
     ]
   }
   ```

4. **Build aplikasi**
   ```bash
   flutter build web --release
   ```

5. **Deploy**
   ```bash
   vercel --prod
   ```

### **Metode 2: Deploy via GitHub Integration**

1. **Push code ke GitHub**
   ```bash
   git add .
   git commit -m "Prepare for deployment"
   git push origin main
   ```

2. **Setup di Vercel Dashboard**
   - Buka [vercel.com](https://vercel.com)
   - Klik "New Project"
   - Import repository GitHub Anda
   - Vercel akan otomatis detect `vercel.json` yang sudah ada di project
   - **PENTING**: Pastikan file `vercel.json` sudah ada di root project

3. **Add Environment Variables (WAJIB!)**
   - Di Vercel dashboard, masuk ke **Project Settings** > **Environment Variables**
   - Tambahkan environment variables berikut:
     - **Name:** `SUPABASE_URL`
       **Value:** `https://your-project-id.supabase.co`
       **Environment:** Production, Preview, Development (centang semua)
     
     - **Name:** `SUPABASE_ANON_KEY`
       **Value:** `your-anon-key-here`
       **Environment:** Production, Preview, Development (centang semua)
   
   **Cara mendapatkan credentials:**
   - Login ke [Supabase Dashboard](https://app.supabase.com)
   - Pilih project Anda
   - Buka **Settings** > **API**
   - Copy **Project URL** dan **anon/public key**

4. **Deploy**
   - Klik "Deploy"
   - Vercel akan otomatis:
     1. Install Flutter SDK
     2. Run `flutter pub get`
     3. Build dengan environment variables: `flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
     4. Deploy folder `build/web`

### **Konfigurasi untuk Flutter Web**

File `vercel.json` sudah dibuat di root project dengan konfigurasi yang benar:

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
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=3600"
        }
      ]
    },
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

**Penjelasan:**
- `buildCommand`: Build Flutter web dengan environment variables dari Vercel
- `outputDirectory`: Folder output build (`build/web`)
- `installCommand`: Install Flutter SDK dan dependencies
- `rewrites`: Redirect semua route ke `index.html` (untuk Flutter routing)
- `headers`: Cache control untuk optimasi performa

**⚠️ PENTING:**
1. Pastikan environment variables `SUPABASE_URL` dan `SUPABASE_ANON_KEY` sudah ditambahkan di Vercel dashboard
2. Build command menggunakan `--dart-define` untuk pass environment variables ke Flutter
3. Vercel akan otomatis download Flutter SDK saat build (ini akan memakan waktu beberapa menit)

---

## 🚢 Deploy ke Netlify

Netlify juga sangat mudah untuk deploy Flutter web apps.

### **Metode 1: Deploy via Netlify CLI**

1. **Install Netlify CLI**
   ```bash
   npm install -g netlify-cli
   ```

2. **Login**
   ```bash
   netlify login
   ```

3. **Buat file `netlify.toml` di root project**
   ```toml
   [build]
     command = "flutter build web --release"
     publish = "build/web"

   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

4. **Build dan Deploy**
   ```bash
   flutter build web --release
   netlify deploy --prod
   ```

### **Metode 2: Deploy via Netlify Dashboard**

1. **Build aplikasi**
   ```bash
   flutter build web --release
   ```

2. **Drag & Drop**
   - Buka [app.netlify.com](https://app.netlify.com)
   - Drag folder `build/web` ke Netlify dashboard
   - Netlify akan otomatis deploy

3. **Setup Continuous Deployment**
   - Connect dengan GitHub
   - Set build command: `flutter build web --release`
   - Set publish directory: `build/web`

### **File `netlify.toml` Lengkap**

```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "stable"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=3600"

[[headers]]
  for = "/*.css"
  [headers.values]
    Cache-Control = "public, max-age=3600"
```

---

## 🔥 Deploy ke Firebase Hosting

Firebase Hosting adalah pilihan yang baik untuk aplikasi Flutter.

### **Setup Firebase**

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login**
   ```bash
   firebase login
   ```

3. **Initialize Firebase**
   ```bash
   firebase init hosting
   ```

   Pilih:
   - Use existing project atau create new
   - Public directory: `build/web`
   - Configure as single-page app: **Yes**
   - Set up automatic builds: **No** (atau Yes jika ingin CI/CD)

4. **File `firebase.json` akan dibuat:**
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": [
         "firebase.json",
         "**/.*",
         "**/node_modules/**"
       ],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ],
       "headers": [
         {
           "source": "**/*.@(js|css)",
           "headers": [
             {
               "key": "Cache-Control",
               "value": "max-age=3600"
             }
           ]
         },
         {
           "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
           "headers": [
             {
               "key": "Cache-Control",
               "value": "max-age=31536000"
             }
           ]
         }
       ]
     }
   }
   ```

5. **Build dan Deploy**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

### **Setup CI/CD dengan GitHub Actions**

Buat file `.github/workflows/firebase-deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

---

## 📄 Deploy ke GitHub Pages

GitHub Pages adalah pilihan gratis untuk hosting static sites.

### **Setup GitHub Pages**

1. **Build aplikasi**
   ```bash
   flutter build web --release --base-href "/sigap_app/"
   ```
   (Ganti `sigap_app` dengan nama repository Anda)

2. **Buat script deploy**

   Buat file `deploy.sh`:
   ```bash
   #!/bin/bash
   set -e
   
   echo "Building Flutter web app..."
   flutter build web --release --base-href "/sigap_app/"
   
   echo "Copying build to gh-pages branch..."
   git stash
   git checkout gh-pages
   rm -rf *
   cp -r build/web/* .
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push origin gh-pages
   git checkout main
   git stash pop
   
   echo "Deployment complete!"
   ```

3. **Setup GitHub Actions**

   Buat file `.github/workflows/deploy.yml`:
   ```yaml
   name: Deploy to GitHub Pages
   
   on:
     push:
       branches:
         - main
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         
         - name: Setup Flutter
           uses: subosito/flutter-action@v2
           with:
             flutter-version: 'stable'
         
         - name: Install dependencies
           run: flutter pub get
         
         - name: Build web
           run: flutter build web --release --base-href "/sigap_app/"
         
         - name: Deploy to GitHub Pages
           uses: peaceiris/actions-gh-pages@v3
           with:
             github_token: ${{ secrets.GITHUB_TOKEN }}
             publish_dir: ./build/web
   ```

4. **Enable GitHub Pages**
   - Repository Settings > Pages
   - Source: GitHub Actions
   - Save

---

## 🔐 Konfigurasi Environment Variables

### **Untuk Vercel (WAJIB DILAKUKAN!)**

**Langkah-langkah:**

1. **Masuk ke Vercel Dashboard**
   - Buka [vercel.com](https://vercel.com)
   - Login ke akun Anda
   - Pilih project SIGAP Anda

2. **Tambah Environment Variables**
   - Klik **Settings** di menu project
   - Klik **Environment Variables** di sidebar
   - Klik **Add New** untuk menambah variable baru

3. **Tambahkan SUPABASE_URL**
   - **Name:** `SUPABASE_URL`
   - **Value:** `https://your-project-id.supabase.co` (ganti dengan URL Supabase Anda)
   - **Environment:** Centang semua (Production, Preview, Development)
   - Klik **Save**

4. **Tambahkan SUPABASE_ANON_KEY**
   - **Name:** `SUPABASE_ANON_KEY`
   - **Value:** `your-anon-key-here` (ganti dengan anon key Supabase Anda)
   - **Environment:** Centang semua (Production, Preview, Development)
   - Klik **Save**

5. **Redeploy Setelah Menambah Variables**
   - Setelah menambah environment variables, klik **Deployments**
   - Klik menu (3 dots) pada deployment terbaru
   - Pilih **Redeploy** untuk rebuild dengan environment variables baru

**Cara Mendapatkan Credentials:**
- Login ke [Supabase Dashboard](https://app.supabase.com)
- Pilih project Anda
- Buka **Settings** (icon gear) > **API**
- Copy **Project URL** → ini adalah `SUPABASE_URL`
- Copy **anon/public key** → ini adalah `SUPABASE_ANON_KEY`

**⚠️ PENTING:**
- Jangan commit credentials ke repository!
- Environment variables di Vercel hanya bisa diakses saat build time
- Pastikan environment variables sudah ditambahkan sebelum deploy pertama kali

### **Untuk Netlify**

1. Masuk ke Site Settings > Environment Variables
2. Tambahkan variables yang sama

### **Untuk Firebase**

1. Masuk ke Firebase Console > Project Settings
2. Tambahkan di Config atau gunakan Firebase Functions untuk handle secrets

### **Setup Environment Variables untuk Development**

1. Copy file `.env.example` ke `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit file `.env` dan isi dengan credentials Supabase Anda:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. File `.env` sudah ada di `.gitignore`, jadi tidak akan ter-commit.

### **Build dengan Environment Variables (Production)**

Untuk production build, gunakan compile-time environment variables:

```bash
# Flutter build dengan environment variables
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Atau untuk Android/iOS:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**Note**: Code sudah di-update untuk menggunakan `AppConfig` dari `lib/core/config.dart` yang membaca dari:
1. `.env` file (untuk development)
2. Compile-time environment variables (untuk production)
3. Fallback ke empty string dengan error message yang jelas

Update `lib/main.dart` sudah dilakukan:
```dart
await SupabaseService.initialize(
  supabaseUrl: AppConfig.supabaseUrl,
  supabaseAnonKey: AppConfig.supabaseAnonKey,
);
```

**Build dengan environment variables:**
```bash
flutter build web --release --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

---

## 🌍 Setup Custom Domain

### **Vercel**

1. Masuk ke Project Settings > Domains
2. Add domain
3. Follow instruksi untuk setup DNS:
   - Add CNAME record: `your-domain.com` → `cname.vercel-dns.com`
   - Atau A record: `your-domain.com` → `76.76.21.21`

### **Netlify**

1. Masuk ke Site Settings > Domain Management
2. Add custom domain
3. Setup DNS:
   - Add A record: `@` → `75.2.60.5`
   - Add CNAME: `www` → `your-site.netlify.app`

### **Firebase**

1. Masuk ke Firebase Console > Hosting
2. Add custom domain
3. Follow instruksi untuk verify domain
4. Setup DNS records yang diberikan

---

## ✅ Testing Setelah Deploy

### **Checklist Testing**

1. ✅ **Homepage Loading**
   - Buka URL production
   - Pastikan halaman login muncul

2. ✅ **Login Functionality**
   - Test login dengan credentials valid
   - Test login dengan credentials invalid

3. ✅ **Navigation**
   - Test semua navigasi di aplikasi
   - Pastikan tidak ada 404 error

4. ✅ **API Calls**
   - Test semua fitur yang menggunakan API
   - Pastikan Supabase connection berfungsi

5. ✅ **Responsive Design**
   - Test di berbagai ukuran layar
   - Test di mobile, tablet, desktop

6. ✅ **Performance**
   - Check loading time
   - Check bundle size
   - Optimize jika perlu

7. ✅ **Security**
   - Pastikan HTTPS aktif
   - Pastikan credentials tidak ter-expose di client-side code

### **Tools untuk Testing**

- **Lighthouse**: Test performance, accessibility, SEO
  ```bash
  npm install -g lighthouse
  lighthouse https://your-site.com
  ```

- **PageSpeed Insights**: [pagespeed.web.dev](https://pagespeed.web.dev)

---

## 🔧 Troubleshooting

### **Problem: Build Error**

**Solusi:**
```bash
# Clear build cache
flutter clean
flutter pub get
flutter build web --release
```

### **Problem: 404 Error pada Route**

**Solusi:**
- Pastikan rewrite rules sudah benar
- Pastikan `index.html` ada di root
- Check base-href configuration

### **Problem: CORS Error**

**Solusi:**
- Pastikan Supabase CORS settings sudah benar
- Tambahkan domain production ke Supabase allowed origins

### **Problem: Environment Variables Tidak Terbaca**

**Solusi:**
- Pastikan variables sudah di-set di platform hosting
- Rebuild aplikasi setelah menambah variables
- Check apakah menggunakan `--dart-define` dengan benar

### **Problem: Assets Tidak Load**

**Solusi:**
- Pastikan path assets benar
- Check `pubspec.yaml` assets configuration
- Pastikan base-href sesuai dengan deployment path

### **Problem: Performance Lambat**

**Solusi:**
- Enable compression di hosting platform
- Optimize images
- Use CDN untuk static assets
- Enable caching headers

---

## 📊 Monitoring & Analytics

### **Setup Error Tracking**

1. **Sentry**
   ```dart
   // pubspec.yaml
   dependencies:
     sentry_flutter: ^7.0.0
   ```

2. **Firebase Crashlytics**
   - Setup di Firebase Console
   - Integrate di Flutter app

### **Setup Analytics**

1. **Google Analytics**
   - Setup di Firebase Console
   - Track user events

2. **Custom Analytics**
   - Track dengan Supabase
   - Log user actions

---

## 🔄 Continuous Deployment (CI/CD)

### **GitHub Actions Workflow**

Buat file `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./
```

---

## 📝 Checklist Deploy

### **Sebelum Deploy**
- [ ] Update environment variables
- [ ] Test build lokal
- [ ] Check semua fitur berfungsi
- [ ] Optimize images dan assets
- [ ] Update version number
- [ ] Update changelog

### **Saat Deploy**
- [ ] Build aplikasi
- [ ] Deploy ke staging (jika ada)
- [ ] Test di staging
- [ ] Deploy ke production
- [ ] Verify deployment

### **Setelah Deploy**
- [ ] Test semua fitur utama
- [ ] Check error logs
- [ ] Monitor performance
- [ ] Update dokumentasi
- [ ] Notify team

---

## 🎯 Best Practices

1. **Selalu test di staging sebelum production**
2. **Gunakan environment variables untuk secrets**
3. **Enable HTTPS untuk semua domain**
4. **Setup monitoring dan error tracking**
5. **Keep dependencies updated**
6. **Optimize bundle size**
7. **Use CDN untuk static assets**
8. **Enable caching untuk better performance**
9. **Setup backup dan recovery plan**
10. **Document semua deployment steps**

---

## 📚 Referensi

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Documentation](https://vercel.com/docs)
- [Netlify Documentation](https://docs.netlify.com/)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [GitHub Pages](https://docs.github.com/en/pages)

---

## 💡 Tips Tambahan

1. **Gunakan staging environment** untuk test sebelum production
2. **Setup rollback plan** jika ada masalah
3. **Monitor error logs** secara berkala
4. **Keep backup** dari setiap deployment
5. **Document semua changes** untuk easy rollback

---

**Selamat Deploy! 🚀**

