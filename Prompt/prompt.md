# Context: iOS App Standalone untuk Matching Warna Outfit

## Tujuan
Membangun aplikasi iOS **standalone / offline** tanpa internet dan tanpa third party selain framework dari Apple, yang membantu user dalam:

1. **Lemari digital (CRUD)**  
   Menyimpan data pakaian user secara lokal.

2. **Matching warna outfit**  
   Mencocokkan **atasan** dengan **bawahan** dan sebaliknya berdasarkan **warna outfit saja**.

3. **Scan pakaian baru**  
   Mengambil warna utama pakaian dari foto / kamera untuk kemudian dijadikan dasar rekomendasi.

---

## Prinsip Utama
- App berjalan **full offline**
- Tidak menggunakan **image classification**
- Tidak menggunakan **skin tone** dan **undertone**
- Fokus hanya pada **warna pakaian**
- Rekomendasi diambil dari **pakaian lawan kategori yang sudah disimpan di database**
- **ISCC–NBS** hanya digunakan untuk **penamaan warna**, bukan untuk menghitung kecocokan

---

## Scope Fitur

### 1. Lemari Digital
User dapat:
- menambah pakaian
- melihat daftar pakaian
- mengedit data pakaian
- menghapus pakaian

Minimal data yang disimpan:
- `id`
- `itemName`
- `category` (`top` / `bottom`)
- `image`
- `itemDescription`
- `dominantColor`
- representasi warna untuk logic (mis. `hue`, `saturation`, `brightness`)
- `isccNbsName`
- `idItemPairs`

---

### 2. Matching Atasan dan Bawahan
Sistem hanya mencocokkan:
- **atasan → bawahan**
- **bawahan → atasan**

Dasar pencocokan:
- **warna outfit**
- menggunakan **color harmony rule-based logic** di codingan

---

### 3. Scan Pakaian Baru
Flow scan yang dipakai adalah **scan terkontrol**, bukan klasifikasi gambar.

#### Flow:
1. User memilih mode:
   - `Scan Atasan`
   - `Scan Bawahan`

2. Kamera / gallery dibuka

3. User mengarahkan pakaian ke **placeholder / area scope warna**

4. Sistem mengambil warna dari area tersebut

5. Warna utama pakaian disimpan ke database

#### Catatan:
- Tidak ada proses **image classification**
- Tidak ada proses menentukan otomatis ini atasan atau bawahan
- Jenis item sudah diketahui dari mode yang dipilih user
- Placeholder digunakan sebagai **scope warna yang diambil**

---

## Framework Apple yang Dipakai
Kemungkinan stack Apple-only yang relevan:

- **SwiftUI** → UI
- **SwiftData** → local persistence / database
- **Vision / Core Image** → jika dibutuhkan untuk pemrosesan gambar dasar
- **UIKit / PhotosUI / AVFoundation** → kamera / gallery sesuai kebutuhan implementasi

> Karena scope scan sekarang memakai placeholder area warna, fokus utamanya bukan deteksi objek, tetapi pengambilan warna dari area yang dipilih.

---

## Color Harmony yang Digunakan
Sistem rekomendasi menggunakan 5 jenis harmony:

1. **Analogous**
2. **Monochromatic**
3. **Complementary**
4. **Split Complementary**
5. **Triadic**

---

## Aturan Dasar Harmony
Color harmony akan dibuat sebagai **logic di codingan**, bukan AI / ML.

### Inti Logic
- Ambil warna utama dari item sumber
- Bandingkan dengan warna item kandidat
- Nilai apakah kandidat masuk ke salah satu kategori harmony
- Hitung skor kecocokan
- Urutkan hasil dari yang paling cocok

### Representasi warna
Untuk scoring, warna hasil scan / simpan sebaiknya dikonversi ke bentuk yang mudah dihitung, misalnya:
- `Hue`
- `Saturation`
- `Brightness`

ISCC–NBS **bukan** dipakai untuk scoring, hanya untuk penamaan.

---

## Peran ISCC–NBS
ISCC–NBS digunakan hanya untuk:

- memberi **nama warna** dari warna yang sudah didapat
- menjadi label yang ditampilkan ke user

### Bukan untuk:
- menghitung harmony
- menentukan score kecocokan
- menjadi engine utama rekomendasi

### Alur:
1. warna numerik didapat dari scan / data pakaian
2. warna numerik disimpan
3. warna tersebut dipetakan ke nama ISCC–NBS terdekat
4. nama warna digunakan untuk tampilan

---

## Sumber Rekomendasi
Rekomendasi warna **berasal dari pakaian yang sudah disimpan**.

### Flow rekomendasi:
1. Ambil satu pakaian yang dipilih / discan
2. Cari semua pakaian dari **kategori lawan** di database
   - jika source = `top`, ambil semua `bottom`
   - jika source = `bottom`, ambil semua `top`
3. Hitung kecocokan tiap kandidat berdasarkan color harmony
4. Urutkan hasil
5. Tampilkan kandidat terbaik

### Contoh:
- User memilih **atasan A**
- Sistem mengambil semua **bawahan** yang tersimpan
- Sistem menghitung harmony score antara atasan A dengan tiap bawahan
- Sistem menampilkan bawahan dengan skor tertinggi

---

## Persentase Kecocokan vs Tanpa Persentase

### Kesimpulan
**Logic inti tetap sama.**

Yang berubah hanya cara hasilnya ditampilkan.

### Jika memakai persentase:
- sistem tetap menghitung skor
- skor dinormalisasi ke `0...100`
- UI menampilkan misalnya `89% Match`

### Jika tidak memakai persentase:
- sistem tetap menghitung skor
- hasil hanya dipakai untuk ranking / sorting
- UI bisa menampilkan:
  - `Best Match`
  - `Good Match`
  - `Recommended`

### Jadi:
- **core logic** = sama
- **perbedaan** = hanya di output / presentasi UI

### Rekomendasi implementasi
Secara internal tetap simpan / gunakan:
- `raw score`

Lalu di UI bisa pilih:
- tampilkan persen
- atau tidak tampilkan persen

---

## Arah Implementasi Logic
Sistem sebaiknya tetap memiliki scoring internal.

Contoh konsep hasil pencocokan:

- item kandidat
- jenis harmony yang cocok
- raw score
- optional percentage

Tujuannya:
- mudah untuk sorting
- mudah untuk tuning rule
- mudah untuk debugging
- fleksibel untuk UI

---

## Ringkasan Keputusan
1. App fokus hanya pada **warna outfit**
2. Tidak menggunakan **skin tone** dan **undertone**
3. Tidak menggunakan **image classification**
4. Scan memakai **placeholder / scope area warna**
5. Harmony dibuat sebagai **rule-based logic di code**
6. Harmony yang dipakai:
   - analogous
   - monochromatic
   - complementary
   - split complementary
   - triadic
7. **ISCC–NBS** hanya untuk **penamaan warna**
8. Rekomendasi diambil dari **pakaian lawan kategori yang sudah disimpan**
9. Persentase atau tidak persentase **tidak mengubah logic inti**, hanya cara menampilkan hasil

---

## Goal MVP
MVP difokuskan pada alur berikut:

1. User menyimpan pakaian ke lemari digital
2. User scan / input warna pakaian baru
3. Sistem menyimpan warna utama pakaian
4. Sistem memberi nama warna dengan ISCC–NBS
5. User memilih satu pakaian
6. Sistem mencari pasangan terbaik dari kategori lawan berdasarkan color harmony
7. Sistem menampilkan rekomendasi outfit