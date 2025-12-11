# 🌐 Panduan Menjalankan SIGAP di Web

## Menjalankan Aplikasi Web

### Development Mode

```bash
flutter run -d chrome
```

Flutter 3.29.3 secara default akan menggunakan HTML renderer untuk development, yang tidak memerlukan CanvasKit dari CDN.

### Build untuk Production

```bash
# Build dengan HTML renderer (lebih ringan, tidak perlu CanvasKit)
flutter build web --release

# Atau jika ingin menggunakan CanvasKit (lebih stabil untuk animasi kompleks)
flutter build web --release
```

## Troubleshooting

### Error: Failed to fetch CanvasKit

Jika Anda mengalami error loading CanvasKit dari CDN, Flutter akan otomatis fallback ke HTML renderer. HTML renderer adalah default untuk development mode.

### Error: window.flutterConfiguration is deprecated

Jangan gunakan `window.flutterConfiguration` di `index.html`. Flutter 3.29.3 sudah menggunakan engineInitializer API secara otomatis.

## Catatan

- HTML renderer lebih ringan dan tidak memerlukan koneksi ke CDN
- CanvasKit memberikan rendering yang lebih baik untuk animasi kompleks
- Untuk aplikasi SIGAP, HTML renderer sudah cukup untuk semua fitur

