# Dokumentasi Fitur 5: Riwayat & Pengaturan Preferensi Pengguna

Fitur **Riwayat & Pengaturan Preferensi Pengguna** memberikan infrastruktur untuk menyimpan riwayat hasil kompresi gambar serta mengatur perilaku default aplikasi demi mempercepat proses kerja harian pengguna.

---

## 1. Penyimpanan Riwayat Optimasi (SQLite & Web Fallback)

Setiap kali proses optimasi (baik gambar tunggal maupun massal) berhasil diselesaikan, data ringkasan disimpan secara otomatis. Penyimpanan ini diatur oleh `DatabaseHelper` ([database_helper.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/data/datasources/local/database_helper.dart)):

*   **Penyimpanan Perangkat Seluler (Android/iOS)**: Memanfaatkan SQLite melalui pustaka `sqflite`.
*   **Penyimpanan Flutter Web**: Karena SQLite tidak didukung secara native pada platform web, sistem mendeteksi bendera `kIsWeb` dan secara otomatis mengalihkan penyimpanan ke *in-memory list* lokal dengan pengurutan berbasis tanggal terbaru (`created_at DESC`).

### A. Skema Tabel SQLite (`history`):

```sql
CREATE TABLE history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    original_name TEXT NOT NULL,
    original_path TEXT NOT NULL,
    optimized_path TEXT NOT NULL,
    original_size INTEGER NOT NULL,
    optimized_size INTEGER NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    format TEXT NOT NULL,
    created_at TEXT NOT NULL,
    is_favorite INTEGER NOT NULL DEFAULT 0
)
```

### B. UI Riwayat (`history_screen.dart` & `history_detail_screen.dart`)
1.  **Daftar Riwayat**: Ditampilkan di `HistoryScreen` ([history_screen.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/presentation/screens/history/history_screen.dart)) dalam susunan kartu terurut tanggal pembuatan.
2.  **Operasi Riwayat**:
    *   **Hapus Item Tunggal**: Pengguna dapat menggeser (*dismissible*) atau menekan tombol hapus pada kartu riwayat untuk memanggil metode `deleteItem(item.id)`.
    *   **Hapus Semua**: Opsi "Bersihkan Riwayat" untuk mengosongkan seluruh isi tabel via `clearAll()`.
3.  **Detail Item**: Menekan kartu akan membuka `HistoryDetailScreen` ([history_detail_screen.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/presentation/screens/history/history_detail_screen.dart)) untuk meninjau metadata gambar, perbandingan resolusi, perbandingan ukuran file (beserta persentase rasio kompresi), jalur penyimpanan berkas fisik, dan opsi untuk menghapus atau membagikan gambar.

---

## 2. Pengaturan Preferensi Pengguna (`PreferencesDatasource`)

Pengaturan aplikasi bersifat global dan bertahan meski aplikasi ditutup. Pengaturan ini dikelola oleh `PreferencesDatasource` ([preferences_datasource.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/data/datasources/local/preferences_datasource.dart)) menggunakan `shared_preferences`.

### A. Pengaturan yang Tersedia:

1.  **Tampilan Tema (`isDarkMode`)**:
    *   Mengatur tampilan visual aplikasi (Tema Terang vs Tema Gelap).
    *   Penerapan tema diatur secara reaktif melalui `themeMode` pada `PromptixApp` di `main.dart`.
2.  **Format Output Default (`outputFormat`)**:
    *   Format default yang akan langsung dipilih secara otomatis di layar optimasi (`JPEG`, `PNG`, atau `WebP`).
3.  **Kualitas Default (`jpgQuality`)**:
    *   Persentase kualitas default untuk file JPEG/WebP (default: `90%`).
4.  **Awalan Nama Berkas (`filePrefix`)**:
    *   Awalan default untuk penamaan file hasil optimasi (default: `PROMPTIX_`).
5.  **Folder Output Kustom (`customOutputPath`)**:
    *   Jalur folder khusus tempat menyimpan gambar hasil optimasi jika pengguna tidak ingin menggunakan folder standar `/Pictures/Promptix`.

Seluruh pengaturan dibungkus dalam model data `AppSettingsEntity` ([app_settings_entity.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/domain/entities/app_settings_entity.dart)) dan disinkronkan ke UI menggunakan `settingsNotifierProvider` berbasis Riverpod di `SettingsScreen` ([settings_screen.dart](file:///c:/Users/NCN0C/Documents/promptix/lib/presentation/screens/settings/settings_screen.dart)).
