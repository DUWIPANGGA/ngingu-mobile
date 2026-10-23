# Ngingu — Mobile Client (Flutter)

Klien Android untuk **Ngingu**: prediksi penyakit ikan berbasis foto (AI) + platform
komunitas tambak (forum, ensiklopedia, peta sebaran wabah).

- Kontrak API: [`../API.md`](../API.md) v1.0.2 — **satu-satunya sumber endpoint yang dipakai**
- Spesifikasi: [`../SRS.md`](../SRS.md) v1.0.4 (desain sistem §7)
- Backend (Laravel): [`../Kaliwedi-Backend`](../Kaliwedi-Backend)

> Klien ini di-rebuild penuh dari aplikasi lama (Kaliwedi, banjir) — modul banjir sudah
> dihapus; nama package Android saat ini `ngingu.duvi.com` (berubah dari `com.miomidev.kaliwedi`,
> sehingga terpasang sebagai aplikasi terpisah dari versi lama).

## Stack

Flutter 3.44.x · Dart ^3.11.5 · **GetX** (state, routing, bindings) · dio (envelope
`{success,message,data,meta}`) · flutter_map · google_fonts (Nunito + Plus Jakarta Sans) ·
image_picker · cached_network_image · share_plus · google_sign_in.

## Menjalankan

```sh
flutter pub get

# Default: API produksi https://ngingu.duvi.asia/api (tanpa --dart-define)
flutter run

# Atau lewat helper (default juga ngingu.duvi.asia, -Local untuk backend lokal):
.\run_dev.ps1
.\run_dev.ps1 -Local

# Emulator Android + backend lokal:
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api

# Perangkat fisik, backend di PC yang sama jaringan:
flutter run --dart-define=API_URL=http://192.168.x.x:8000/api
```

Build rilis (butuh keystore): `flutter build apk --release`.
Debug: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`.

## Verifikasi

```sh
flutter analyze   # harus "No issues found!"
flutter test
```

## Struktur

```
lib/
├── main.dart              # bootstrap: ApiClient + AuthService + NotificationService
├── routes/                # app_routes (nama) + app_pages (GetPage + bindings)
├── core/
│   ├── config/            # AppConfig (API_URL dart-define, limit upload/poll)
│   ├── network/           # ApiClient — envelope parser, long-poll, multipart, download
│   ├── models/            # data models (user, scan, disease, forum, pond, dll.)
│   ├── services/          # AuthService (sesi), NotificationService (badge poll 60s)
│   ├── theme/             # AppColors (SRS §7.2) + AppTheme (light/dark, snackbar)
│   ├── widgets/           # tombol/field/badge/feedback + NginguLogo
│   └── utils/             # time_utils (id), image_utils (kompres <500KB)
└── modules/               # fitur — satu folder per fitur (controllers/ + views/)
    splash · onboarding · welcome · auth · main_navigation · home · scan ·
    encyclopedia · forum · notification · profile · ponds · heatmap · help
```

Konvensi: route bernama lewat `Routes.*` + `BindingsBuilder` di `app_pages.dart`
(constructors no-arg); navigasi lintas modul hanya via route + `Get.arguments`
(`{'id'}`, `{'scanId'}` — lihat catatan di tiap agent/pengembang).

## Perilaku penting

- **Long-poll scan**: `POST /scans` → `GET /scans/{id}?wait=300` (Dio timeout 320s) di
  `ScanProcessingController` — jangan pendekkan timeout-nya.
- **Envelope**: semua error dilempar sebagai `ApiResult(success:false)` — pakai
  `res.errorText` / `res.fieldError('nama_field')`, jangan try/catch.
- **Tamu**: encyclopedia + detail penyakit publik; scan/forum/profil minta login.
- **Notifikasi**: badge di-poll tiap 60s (`NotificationService`, GetxService permanent).

## Known gaps (scope = endpoint API.md saja)

- **FR-08.5 follow pengguna** — tidak ada endpoint; `is_following` selalu `false`,
  tombol Follow sengaja tidak dibuat.
- **Verifikasi email / OTP in-app** — backend kirim link verifikasi via email, tidak ada
  endpoint verifikasi dari aplikasi (reset password = tempel token dari email).
- **Artikel (FR-03.3)** — tidak ada endpoint; konten edukasi di-deliver via Ensiklopedia.
- **Launcher icon** masih memakai aset lama (`assets/images/logo.png`,
  flutter_launcher_icons) — ganti dengan ikon Ngingu sebelum rilis.
- **Ubah password** = `PUT /api/user/password` (API.md §7.12, sudah diimplementasi backend).
- **Detail penyakit**: backend menerima slug **atau** id numerik (API.md §5.2).
