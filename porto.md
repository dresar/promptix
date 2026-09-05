# <span style="font-size: 24px; color: #6c5ce7;">🛠️ PORTFOLIO PROJECT: Promptix 📸</span>

<div style="padding: 15px; border-radius: 8px; background: rgba(108, 92, 231, 0.08); border-left: 5px solid #6c5ce7; margin-bottom: 20px; font-size: 13px; line-height: 1.6; opacity: 0.95;">
  <strong>Promptix — AI Metadata Cleaner & Image Spoofer</strong> adalah aplikasi utilitas berbasis Flutter yang dirancang untuk melindungi privasi pengguna di era kecerdasan buatan. Aplikasi ini membersihkan jejak digital gambar secara lokal (offline) dengan menargetkan tanda tangan AI generatif dan metadata provenance (C2PA) pada level biner raw byte, sembari memalsukan informasi EXIF secara dinamis menggunakan profil perangkat fisik kustom.
</div>

---

### <span style="font-size: 18px; color: #2e86de;">💼 Ringkasan Detail Proyek (Project Details)</span>

<table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 20px; border: 1px solid rgba(128, 128, 128, 0.2);">
  <thead>
    <tr style="background-color: #6c5ce7; color: white;">
      <th style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); text-align: left;">🏷️ Parameter</th>
      <th style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); text-align: left;">📝 Informasi Proyek</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">Nama Aplikasi</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2);">Promptix (AI Metadata Cleaner & Spoofer)</td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">Teknologi Utama</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2);">
        <span style="color: #6c5ce7; font-weight: bold;">Flutter</span>, 
        <span style="color: #00cec9; font-weight: bold;">Dart</span>, 
        <span style="color: #0984e3; font-weight: bold;">Riverpod</span>, 
        <span style="color: #e84393; font-weight: bold;">GoRouter</span>, 
        <span style="color: #ffeaa7; font-weight: bold; background-color: rgba(128, 128, 128, 0.15); padding: 2px 5px; border-radius: 3px;">SQLite (sqflite)</span>, 
        <span style="color: #1dd1a1; font-weight: bold;">Shared Preferences</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">Arsitektur</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2);">Clean Architecture (Presentation, Domain, Data)</td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">Kategori Produk</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2);">Utilitas Keamanan & Privasi Gambar (Security & Privacy Utility)</td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">Tipe Platform</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2);">Multiplatform (Android, iOS, Web)</td>
    </tr>
  </tbody>
</table>

---

### <span style="font-size: 18px; color: #2e86de;">🛡️ Latar Belakang Masalah (The Problem)</span>

<p style="font-size: 13px; line-height: 1.7; text-align: justify; opacity: 0.85;">
  Di era digital saat ini, setiap gambar yang kita ambil menggunakan smartphone atau yang kita buat menggunakan generator kecerdasan buatan (seperti Midjourney atau DALL-E) menyimpan informasi rahasia yang sangat detail di balik pikselnya. Informasi ini disebut metadata. Data seperti lokasi GPS rumah Anda, waktu presisi pengambilan foto, perangkat lunak editing, hingga metadata provenance C2PA yang menandai gambar sebagai "AI-generated" dapat dengan mudah dilacak oleh platform media sosial dan pihak ketiga yang tidak bertanggung jawab. Leaknya informasi ini merupakan ancaman privasi yang serius. Pengguna membutuhkan cara mudah untuk mengoptimalkan ukuran gambar (agar hemat penyimpanan) tanpa harus membagikan sidik jari digital pribadi mereka.
</p>

---

### <span style="font-size: 18px; color: #2e86de;">💡 Solusi & Rekayasa Rekonstruksi (The Solution)</span>

<p style="font-size: 13px; line-height: 1.7; text-align: justify; opacity: 0.85;">
  Promptix hadir sebagai solusi privasi lokal berperforma tinggi. Tidak hanya membersihkan metadata standar (EXIF/IPTC/XMP), Promptix melakukan <strong>Raw Byte-Level Scrubbing</strong> pada biner berkas gambar JPEG, PNG, dan WebP secara langsung sebelum didecode oleh mesin grafis. Hal ini menjamin bahwa seluruh data identitas tersembunyi benar-benar dibabat habis. Lebih dari itu, Promptix menawarkan fitur <strong>EXIF Spoofing</strong> yang memungkinkan gambar tampak seolah-olah diambil oleh kamera profesional seperti Sony Xperia, Fujifilm, Samsung Ultra, atau iPhone terbaru demi membingungkan pelacak data, lengkap dengan modifikasi lokasi GPS dan manipulasi waktu acak.
</p>

---

### <span style="font-size: 18px; color: #2e86de;">🧩 Fitur Utama & Rincian Teknis (Core Features Breakdown)</span>

<table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 20px; border: 1px solid rgba(128, 128, 128, 0.2);">
  <thead>
    <tr style="background-color: #2e86de; color: white;">
      <th style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); width: 30%; text-align: left;">✨ Fitur</th>
      <th style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); text-align: left;">🔧 Detail Teknis & Algoritma</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">📸 Optimasi & Kompresi Gambar Tunggal</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); line-height: 1.6;">
        <span style="font-size: 12.5px; opacity: 0.9;">
          Mendukung konversi format antara JPEG, PNG, dan WebP dengan kualitas kompresi dinamis. Menghindari pemblokiran utas utama (UI Lag) dengan memindahkan beban kerja pemrosesan biner berat ke dalam utas latar belakang (Isolate) memanfaatkan API <code>compute</code> bawaan Dart.
        </span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">🛡️ Scrubber Biner C2PA & Detektor AI</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); line-height: 1.6;">
        <span style="font-size: 12.5px; opacity: 0.9;">
          Melakukan pemindaian tanda biner di level byte untuk mendeteksi penanda khusus seperti <code>APP11 (0xEB) JUMBF</code> pada JPEG, chunk <code>caBX/c2pa</code> pada PNG, serta chunk <code>XMP</code> pada WebP. Menghapus metadata tanpa melakukan decode ulang berkas terlebih dahulu untuk efisiensi milidetik.
        </span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">⚙️ Pemalsuan Profil EXIF & Lokasi GPS</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); line-height: 1.6;">
        <span style="font-size: 12.5px; opacity: 0.9;">
          Menyediakan preset profil kamera fisik (Canon, Samsung, Sony, dll.) dan pembuatan profil kustom. Menggunakan kalkulasi matematika <code>Rational</code> untuk menulis ulang tag ISO, Aperture, Shutter Speed, serta menyuntikkan koordinat Latitude/Longitude GPS buatan secara akurat.
        </span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">🎨 Mesin Penanda Air (Watermark Engine)</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); line-height: 1.6;">
        <span style="font-size: 12.5px; opacity: 0.9;">
          Menyisipkan logo visual transparan ke atas gambar secara proporsional berdasarkan rasio aspek dan persentase skala lebar gambar target. Mendukung konversi ruang warna RGBA 4-saluran untuk menghindari kerusakan rendering opasitas alpha channel.
        </span>
      </td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); font-weight: bold; background-color: rgba(128, 128, 128, 0.05);">💾 Penyimpanan Riwayat & Sinkronisasi Preferensi</td>
      <td style="padding: 10px; border: 1px solid rgba(128, 128, 128, 0.2); line-height: 1.6;">
        <span style="font-size: 12.5px; opacity: 0.9;">
          Menyimpan hasil riwayat pemrosesan di database lokal terenkripsi <code>SQLite (sqflite)</code> di perangkat seluler, dengan mekanisme fallback memori dinamis di platform Web. Sinkronisasi tema global (Gelap/Terang) dan pengaturan kompresi default disimpan di SharedPreferences.
        </span>
      </td>
    </tr>
  </tbody>
</table>

---

### <span style="font-size: 18px; color: #2e86de;">📐 Arsitektur Sistem & Struktur Repositori (Clean Architecture)</span>

<p style="font-size: 13px; line-height: 1.7; text-align: justify; opacity: 0.85;">
  Aplikasi ini menggunakan pola arsitektur **Clean Architecture** yang ketat untuk menjamin skalabilitas, modularitas, dan kemudahan dalam pengujian unit (*Unit Testing*). Pemisahan tanggung jawab kode dibagi menjadi tiga lapisan utama:
</p>

1.  <strong><span style="color: #6c5ce7;">Presentation Layer</span></strong>:
    *   Mengatur tampilan visual, layar interaktif (`Screens`), widget kustom, dan rute navigasi.
    *   State diatur secara reaktif oleh `StateNotifier` dari Riverpod untuk memperbarui antarmuka pengguna secara instan tanpa membangun ulang elemen UI yang tidak diperlukan.
2.  <strong><span style="color: #00cec9;">Domain Layer</span></strong>:
    *   Menyimpan inti dari aturan bisnis aplikasi.
    *   Berisi berkas `Entities` yang mendefinisikan struktur model murni dan `Usecases` yang memproses alur kerja spesifik (contoh: mengeksekusi penyimpanan riwayat atau pemicuan optimasi). Lapisan ini sepenuhnya independen dan bebas dari framework.
3.  <strong><span style="color: #0984e3;">Data Layer</span></strong>:
    *   Bertanggung jawab atas komunikasi data luar.
    *   Mengimplementasikan `Repositories` untuk bertukar data dengan database `sqflite`, manajer cache `WebImageCache`, preferensi lokal, serta pustaka decoding gambar.

---

### <span style="font-size: 18px; color: #2e86de;">💎 Nilai Pembelajaran & Rekayasa Menarik (Key Engineering Takeaways)</span>

<ul style="font-size: 13px; line-height: 1.8; padding-left: 20px; opacity: 0.85;">
  <li>
    <strong>Komputasi Paralel dengan Isolate</strong>: Memindahkan operasi byte-level dan pixel-drawing ke thread background Dart untuk menjamin UI utama tetap berjalan lancar pada 60/120 FPS bahkan saat memproses foto berukuran besar (15 MB+).
  </li>
  <li>
    <strong>Manipulasi File Binary Tingkat Rendah</strong>: Mempelajari dan merancang sendiri algoritma parsing biner untuk format JPEG (APP markers), PNG (chunks), dan WebP (RIFF blocks) guna mengidentifikasi dan membuang metadata provenance secara akurat tanpa merusak berkas.
  </li>
  <li>
    <strong>Sinkronisasi Lintas Platform (Hybrid Storage)</strong>: Membangun sistem penyimpanan hibrida yang secara cerdas beralih menggunakan SQLite lokal pada Android/iOS dan menggunakan fallback cache memori pada web browser agar kode sumber tetap bersih (*single codebase*).
  </li>
  <li>
    <strong>Integrasi Native OS</strong>: Memicu pemindaian media eksternal Android melalui saluran komunikasi platform (<code>MethodChannel</code>) untuk memperbarui galeri bawaan ponsel secara instan saat berkas baru disimpan.
  </li>
</ul>

