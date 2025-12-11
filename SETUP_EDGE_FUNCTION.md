# 🚀 Setup Supabase Edge Function untuk Create User

Panduan untuk deploy Edge Function yang memungkinkan membuat user baru dari aplikasi tanpa perlu masuk ke Supabase Dashboard.

## Prerequisites

1. Supabase CLI sudah terinstall
2. Node.js dan npm sudah terinstall
3. Project Supabase sudah dibuat

## Step 1: Install Supabase CLI

Jika belum terinstall, pilih salah satu metode berikut:

### Metode 1: Menggunakan Scoop (Recommended untuk Windows)

```powershell
# Install Scoop (jika belum ada)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Metode 2: Menggunakan npm (Paling Mudah - Cross Platform)

```bash
# Pastikan Node.js sudah terinstall
npm install -g supabase

# Verifikasi instalasi
supabase --version
```

### Metode 3: Download Manual (Windows)

1. Buka https://github.com/supabase/cli/releases
2. Download file `supabase_windows_amd64.zip` dari release terbaru
3. Extract file zip
4. Pindahkan `supabase.exe` ke folder yang ada di PATH (misalnya `C:\Windows\System32\`)

Atau gunakan PowerShell:

```powershell
# Download dari release spesifik (ganti v1.xxx.xxx dengan versi terbaru)
$version = "v1.200.0"  # Cek versi terbaru di https://github.com/supabase/cli/releases
$url = "https://github.com/supabase/cli/releases/download/$version/supabase_windows_amd64.zip"
Invoke-WebRequest -Uri $url -OutFile "supabase.zip"
Expand-Archive -Path "supabase.zip" -DestinationPath "."
Move-Item -Path "supabase.exe" -Destination "C:\Windows\System32\" -Force
Remove-Item "supabase.zip"
```

### Metode 4: Menggunakan Chocolatey (Windows)

```powershell
# Install Chocolatey (jika belum ada)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Supabase CLI
choco install supabase
```

### Mac

```bash
brew install supabase/tap/supabase
```

### Linux

```bash
curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
sudo mv supabase /usr/local/bin/
```

**Verifikasi instalasi:**
```bash
supabase --version
```

## Step 2: Login ke Supabase

```bash
supabase login
```

Ikuti instruksi untuk login dengan akun Supabase Anda.

## Step 3: Link Project

```bash
# Di root folder project
supabase link --project-ref YOUR_PROJECT_REF
```

**Cara mendapatkan Project Ref:**
1. Buka Supabase Dashboard
2. Klik **Settings** > **General**
3. Copy **Reference ID** (format: `xxxxxxxxxxxxxx`)

Atau gunakan project URL:
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

## Step 4: Deploy Edge Function

```bash
# Deploy function create-user
supabase functions deploy create-user
```

Function akan di-deploy ke Supabase dan otomatis mendapatkan akses ke service role key.

## Step 5: Verify Deployment

1. Buka Supabase Dashboard
2. Klik **Edge Functions** di sidebar
3. Pastikan function `create-user` sudah muncul
4. Klik function tersebut untuk melihat logs

## Step 6: Test Function

Anda bisa test function dari aplikasi atau menggunakan curl:

```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/create-user' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "test@example.com",
    "password": "test123456",
    "nip": "TEST001",
    "full_name": "Test User",
    "base_salary": 0,
    "hourly_rate": 0,
    "presence_rate": 0
  }'
```

## Troubleshooting

### Error: "Not Found" saat download Supabase CLI
- URL `latest/download` kadang tidak stabil
- **Solusi:** Gunakan metode alternatif:
  1. **Gunakan npm** (paling mudah): `npm install -g supabase`
  2. **Download manual** dari https://github.com/supabase/cli/releases
  3. **Gunakan Scoop** (Windows): `scoop install supabase`

### Error: Function not found
- Pastikan function sudah di-deploy dengan benar
- Cek di Supabase Dashboard > Edge Functions
- Pastikan nama function sama persis: `create-user`

### Error: Failed to fetch / Network error
- Edge Function belum di-deploy
- Masalah koneksi internet
- URL Supabase tidak benar
- **Solusi:** 
  1. Deploy Edge Function terlebih dahulu
  2. Atau gunakan opsi "Gunakan User yang Sudah Ada" di form

### Error: Unauthorized
- Pastikan anon key yang digunakan benar
- Cek di Supabase Dashboard > Settings > API

### Error: Service role key not found
- Edge Function otomatis mendapatkan service role key dari environment
- Pastikan function di-deploy dengan benar
- Cek logs di Supabase Dashboard > Edge Functions > create-user > Logs

### Error: Failed to create profile
- Pastikan tabel `profiles` sudah dibuat
- Pastikan RLS policies sudah dikonfigurasi
- Cek apakah user dengan ID tersebut sudah ada di profiles

## Alternative: Manual Setup di Supabase Dashboard

Jika CLI tidak berfungsi, Anda bisa membuat Edge Function manual:

1. Buka Supabase Dashboard
2. Klik **Edge Functions** > **Create a new function**
3. Nama function: `create-user`
4. Copy isi file `supabase/functions/create-user/index.ts`
5. Paste ke editor
6. Klik **Deploy**

## Security Notes

- Edge Function menggunakan service role key yang memiliki akses penuh
- Function hanya bisa dipanggil dengan anon key (tidak perlu service role di client)
- Pastikan RLS policies sudah dikonfigurasi dengan benar
- Function melakukan validasi input sebelum membuat user

## Update Function

Jika perlu update function:

```bash
# Edit file supabase/functions/create-user/index.ts
# Lalu deploy ulang
supabase functions deploy create-user
```

## Monitor Function

Untuk melihat logs dan monitoring:

1. Buka Supabase Dashboard
2. Klik **Edge Functions** > **create-user**
3. Klik tab **Logs** untuk melihat error/request
4. Klik tab **Metrics** untuk melihat usage

## Cost

- Edge Functions di Supabase Free tier: 500,000 invocations/month
- Setiap create user = 1 invocation
- Cukup untuk penggunaan normal


