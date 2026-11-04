import 'dart:async';

// =====================================================
// TUGAS RUTIN 4 - SISTEM PARKIR KAMPUS
// Nama : Syuhada Simbolon
// NIM  : 4243550016
// =====================================================

// =====================================================
// 1. ABSTRACT CLASS KENDARAAN
// =====================================================

abstract class Kendaraan {
  final String plat;
  final DateTime waktuMasuk;

  Kendaraan(this.plat, this.waktuMasuk);

  String get jenis;
  int get tarifPerJam;

  int biaya(DateTime waktuKeluar) {
    final durasi = waktuKeluar.difference(waktuMasuk);

    // Minimal dihitung 1 jam
    final jam = durasi.inMinutes <= 0 ? 1 : (durasi.inMinutes / 60).ceil();

    return jam * tarifPerJam;
  }
}

// =====================================================
// 2. JENIS KENDARAAN
// =====================================================

class Motor extends Kendaraan {
  Motor(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Motor';

  @override
  int get tarifPerJam => 3000;
}

class Mobil extends Kendaraan {
  Mobil(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil';

  @override
  int get tarifPerJam => 5000;
}

class Truk extends Kendaraan {
  Truk(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Truk';

  @override
  int get tarifPerJam => 8000;
}

// =====================================================
// 3. MIXIN DISKON MEMBER
// =====================================================

mixin Berlangganan on Kendaraan {
  @override
  int biaya(DateTime waktuKeluar) {
    final biayaNormal = super.biaya(waktuKeluar);

    // Diskon member 50%
    return (biayaNormal * 0.5).round();
  }
}

class MobilMember extends Mobil with Berlangganan {
  MobilMember(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil (member)';
}

// =====================================================
// 4. EXCEPTION KHUSUS
// =====================================================

class ParkirPenuh implements Exception {
  final String pesan;

  ParkirPenuh(this.pesan);

  @override
  String toString() => 'Ditolak: $pesan';
}

// =====================================================
// 5. CLASS PARKIRAN
// =====================================================

class Parkiran {
  final int kapasitas;

  // Enkapsulasi: data kendaraan bersifat privat
  final Map<String, Kendaraan> _kendaraan = {};

  int _pendapatan = 0;

  final StreamController<String> _log = StreamController<String>.broadcast();

  Parkiran(this.kapasitas);

  int get sisa => kapasitas - _kendaraan.length;

  int get pendapatan => _pendapatan;

  Stream<String> get log => _log.stream;

  // ===================================================
  // KENDARAAN MASUK
  // ===================================================

  Future<void> masuk(Kendaraan kendaraan) async {
    // Simulasi palang otomatis
    await Future.delayed(const Duration(milliseconds: 300));

    if (_kendaraan.length >= kapasitas) {
      throw ParkirPenuh('Parkiran penuh (kapasitas $kapasitas)');
    }

    if (_kendaraan.containsKey(kendaraan.plat)) {
      throw StateError('Kendaraan ${kendaraan.plat} sudah terparkir');
    }

    _kendaraan[kendaraan.plat] = kendaraan;

    _log.add(
      'MASUK ${kendaraan.jenis} '
      '${kendaraan.plat} (sisa $sisa)',
    );
  }

  // ===================================================
  // KENDARAAN KELUAR
  // ===================================================

  Future<int> keluar(String plat, DateTime waktuKeluar) async {
    // Simulasi palang otomatis
    await Future.delayed(const Duration(milliseconds: 300));

    final kendaraan = _kendaraan[plat];

    if (kendaraan == null) {
      throw StateError('Kendaraan dengan plat $plat tidak ditemukan');
    }

    final totalBiaya = kendaraan.biaya(waktuKeluar);

    _pendapatan += totalBiaya;

    _kendaraan.remove(plat);

    _log.add(
      'KELUAR ${kendaraan.jenis} '
      '$plat bayar Rp$totalBiaya',
    );

    return totalBiaya;
  }

  Future<void> tutup() async {
    await _log.close();
  }
}

// =====================================================
// 6. PROGRAM UTAMA
// =====================================================

Future<void> main() async {
  print('================================================');
  print('            SISTEM PARKIR KAMPUS               ');
  print('              FMIPA - UNIMED                   ');
  print('================================================');

  final parkiran = Parkiran(3);

  // Listener Stream menampilkan aktivitas pos jaga
  parkiran.log.listen((pesan) => print('[POS JAGA] $pesan'));

  // Waktu simulasi agar hasil perhitungan konsisten
  final waktuMasuk = DateTime(2026, 11, 4, 8, 0);

  // Polimorfisme: berbagai subclass Kendaraan
  final List<Kendaraan> kendaraan = [
    Motor('BK 1234 AB', waktuMasuk),
    Mobil('BK 88 UN', waktuMasuk),
    MobilMember('BK 7 MIPA', waktuMasuk),
    Truk('BK 9999 TR', waktuMasuk),
  ];

  print('\n=== PENGUJIAN KENDARAAN MASUK ===');

  // Menguji seluruh kendaraan
  for (final k in kendaraan) {
    try {
      await parkiran.masuk(k);
    } on ParkirPenuh catch (e) {
      print(e);
    }
  }

  print('\nSisa tempat parkir: ${parkiran.sisa}');

  // ===================================================
  // PENGUJIAN KENDARAAN KELUAR
  // ===================================================

  print('\n=== PENGUJIAN KENDARAAN KELUAR ===');

  // Motor parkir selama 2 jam
  await parkiran.keluar('BK 1234 AB', DateTime(2026, 11, 4, 10, 0));

  // Mobil parkir selama 3 jam
  await parkiran.keluar('BK 88 UN', DateTime(2026, 11, 4, 11, 0));

  // Mobil member parkir selama 3 jam
  await parkiran.keluar('BK 7 MIPA', DateTime(2026, 11, 4, 11, 0));

  // ===================================================
  // RINGKASAN
  // ===================================================

  print('\n=== RINGKASAN PARKIR ===');

  print('Kapasitas parkir : ${parkiran.kapasitas}');
  print('Sisa tempat      : ${parkiran.sisa}');
  print('Pendapatan       : Rp${parkiran.pendapatan}');

  await parkiran.tutup();

  print('\n================================================');
  print('             PROGRAM SELESAI                    ');
  print('================================================');
}
