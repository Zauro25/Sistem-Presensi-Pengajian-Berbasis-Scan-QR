# Aplikasi Presensi Sesi Kajian Berbasis Mobile

Yo, jadi aing build aplikasi Flutter buat tracking kehadiran sesi kajian, dan honestly? cek sendiri dah. Dashboard berbasis peran (Pengurus flex di Peserta), Firebase yang handle semuanya, dan QR code yang actually works. Legit gak suramnya teh edan.

## Fitur (Yang Juicy)
- **Firebase Auth** – Email/password flows yang enggak berantakan. Roles beneran ada (Pengurus atau Peserta, pilih karakter lu).
- **Manajemen Sesi** – Bikin sesi kajian, tambahin ustadz, generate QR code buat ngaji auto-magically.
- **Tracking Presensi** – Scan QR, build history presensi lu, jangan pernah ghosting sesi lagi.
- **Export CSV** – Export attendance records lu dan flex di spreadsheet. Very "kita hidup di masyarakat" vibes.
- **Dual Dashboard** – Pengurus dapat power (manage semuanya), Peserta chill aja (scan terus cabut).

## Setup (It's Giving Tutorial Energy)
1) Install Flutter (3.19+ is the move) dan run `flutter doctor` biar yakin sistem lu enggak berantakan.
2) Firebase moment:
	- Grab FlutterFire CLI: `dart pub global activate flutterfire_cli`.
	- Run `flutterfire configure` dan biarkan dia bekerja.
	- Ganti placeholder values di `lib/firebase_options.dart` sama Firebase secrets lu yang asli (atau tinggal copy-paste file-nya, gw enggak judge).
3) Dependencies siap: `flutter pub get`.
4) Jalankan: `flutter run` (Android/iOS vibe check). Web? Pastiin Firebase web config lu udah proper.

## Platform Personality (Android vs iOS Arc)
- **Android**: Camera permissions udah dideklarasiin di `android/app/src/main/AndroidManifest.xml`. Respect the vision.
- **iOS**: Camera description ada di `ios/Runner/Info.plist`. Keep bundle ID lu match sama Xcode, atau bakal berantakan.

## Firestore Lore (Schema Bestie)
- `users/{uid}` – nama, email, peran (pengurus/peserta), telepon. Very organized, main character energy.
- `sessions/{id}` – judul, nama guru, lokasi, jadwal, qrCode. The blueprint.
- `attendance/{sessionId_uid}` – sessionId, userId, userName, timestamp, metode, status. Setiap W ter-track.
- `teachers/{id}` – nama, topik, catatan. The real ones behind the scenes.

## QA Checklist (Buat Mastiin Ini Works)
- Bikin akun Pengurus, drop sesi kajian, liat QR code muncul. Gila.
- Switch ke Peserta, scan QR, liat presensi lu pop off real time.
- Export ke CSV, share ke orang-orang, beri mereka receipts attendance lu.
- Login/logout flows? Both roles eating. It's that girl.

Lowkey aplikasi presensi paling dopest yang pernah dibangun. Period.

---

# Mobile-Based Study Session Attendance App

Yo, so we built this Flutter app for tracking attendance at religious study sessions, and honestly? It just hits different. Role-based dashboards (Pengurus flexing on Peserta vibes), Firebase doing the heavy lifting, and QR codes that actually work. No cap.

## Features (The Good Stuff)
- **Firebase Auth** – Email/password flows that don't suck. Roles are real (pengurus or peserta, pick your fighter).
- **Session Management** – Create study sessions, add teachers, vibe-check with auto-generated QR codes.
- **Attendance Tracking** – Scan QR, build your attendance record, never ghost a session again.
- **CSV Export** – Export your attendance receipts and flex them in a spreadsheet. Very "we live in a society" energy.
- **Dual Dashboards** – Pengurus gets the power (manage everything), Peserta gets the chill (just scan and dip).

## Getting Started (It's Giving Setup Tutorial)
1) Install Flutter (3.19+ is the vibe) and run `flutter doctor` to make sure your system isn't broken.
2) Firebase time:
	- Grab FlutterFire CLI: `dart pub global activate flutterfire_cli`.
	- Run `flutterfire configure` and let it cook.
	- Swap the placeholder values in `lib/firebase_options.dart` with your actual Firebase secrets (or just copy-paste the whole file, we won't judge).
3) Dependencies go brr: `flutter pub get`.
4) Run it: `flutter run` (Android/iOS energy). Web? Make sure your Firebase web config is touching grass.

## Platform Flavors (Android vs iOS Arc)
- **Android**: Camera permissions are already declared in `android/app/src/main/AndroidManifest.xml`. Respect the vision.
- **iOS**: Camera description lives in `ios/Runner/Info.plist`. Keep your bundle ID matching Xcode, or it's on sight.

## Firestore Lore (The Schema Bestie)
- `users/{uid}` – name, email, role (pengurus/peserta), phone. Very organized, very main character.
- `sessions/{id}` – title, teacherName, location, scheduledAt, qrCode. The blueprint.
- `attendance/{sessionId_uid}` – sessionId, userId, userName, timestamp, method, status. Every W tracked.
- `teachers/{id}` – name, topic, notes. The real ones behind the scenes.

## QA Checklist (Gotta Make Sure It Works)
- Make a Pengurus account, drop a session, watch that QR code appear. Unhinged.
- Switch to Peserta, scan the QR, see your attendance pop off in real time.
- Export to CSV, share it around, give people receipts of your attendance.
- Login/logout flows? Both roles eating. It's that girl.

Lowkey the dopest attendance app ever built. We're just saying.
