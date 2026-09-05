import 'dart:convert';

/// Entity untuk menyimpan profil metadata EXIF lengkap.
/// Mendukung semua tag EXIF penting + GPS spoofing + timestamp.
class ExifProfileEntity {
  final String id;
  final String name;
  final String iconKey; // nama icon untuk UI
  final bool isBuiltIn; // profil bawaan, tidak bisa dihapus

  // ── Kamera ──────────────────────────────────────────────────────────────────
  final String? cameraMake; // "Apple", "samsung", "SONY"
  final String? cameraModel; // "iPhone 15 Pro", "SM-S928B"
  final String? lensModel; // "Apple iPhone 15 Pro back triple camera"
  final String? software; // "Adobe Photoshop 26.0 (Windows)"

  // ── Exposure ─────────────────────────────────────────────────────────────────
  final int? isoSpeed; // 50 – 6400
  final double? apertureF; // 1.4, 1.8, 2.8 dst (F-number)
  final double? shutterSpeedDenom; // 1/x detik → simpan x saja
  final double? focalLengthMm; // mm
  final int? whiteBalanceMode; // 0=Auto, 1=Manual
  final int? flashMode; // 0=No Flash, 1=Fired

  // ── Kreator ──────────────────────────────────────────────────────────────────
  final String? artistName; // EXIF Artist / XMP dc:creator
  final String? copyright; // EXIF Copyright / XMP dc:rights

  // ── Timestamp ────────────────────────────────────────────────────────────────
  final TimestampMode timestampMode;
  final int timestampOffsetDays; // mundur X hari dari sekarang

  // ── GPS Spoofing ─────────────────────────────────────────────────────────────
  final bool enableGps;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAltitudeM;
  final String gpsLocationName; // label UI saja (mis: "Tokyo, Japan")

  const ExifProfileEntity({
    required this.id,
    required this.name,
    this.iconKey = 'camera_alt',
    this.isBuiltIn = false,
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.software,
    this.isoSpeed,
    this.apertureF,
    this.shutterSpeedDenom,
    this.focalLengthMm,
    this.whiteBalanceMode,
    this.flashMode,
    this.artistName,
    this.copyright,
    this.timestampMode = TimestampMode.current,
    this.timestampOffsetDays = 0,
    this.enableGps = false,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAltitudeM,
    this.gpsLocationName = '',
  });

  ExifProfileEntity copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isBuiltIn,
    String? cameraMake,
    String? cameraModel,
    String? lensModel,
    String? software,
    int? isoSpeed,
    double? apertureF,
    double? shutterSpeedDenom,
    double? focalLengthMm,
    int? whiteBalanceMode,
    int? flashMode,
    String? artistName,
    String? copyright,
    TimestampMode? timestampMode,
    int? timestampOffsetDays,
    bool? enableGps,
    double? gpsLatitude,
    double? gpsLongitude,
    double? gpsAltitudeM,
    String? gpsLocationName,
  }) {
    return ExifProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      lensModel: lensModel ?? this.lensModel,
      software: software ?? this.software,
      isoSpeed: isoSpeed ?? this.isoSpeed,
      apertureF: apertureF ?? this.apertureF,
      shutterSpeedDenom: shutterSpeedDenom ?? this.shutterSpeedDenom,
      focalLengthMm: focalLengthMm ?? this.focalLengthMm,
      whiteBalanceMode: whiteBalanceMode ?? this.whiteBalanceMode,
      flashMode: flashMode ?? this.flashMode,
      artistName: artistName ?? this.artistName,
      copyright: copyright ?? this.copyright,
      timestampMode: timestampMode ?? this.timestampMode,
      timestampOffsetDays: timestampOffsetDays ?? this.timestampOffsetDays,
      enableGps: enableGps ?? this.enableGps,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      gpsAltitudeM: gpsAltitudeM ?? this.gpsAltitudeM,
      gpsLocationName: gpsLocationName ?? this.gpsLocationName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'isBuiltIn': isBuiltIn,
        'cameraMake': cameraMake,
        'cameraModel': cameraModel,
        'lensModel': lensModel,
        'software': software,
        'isoSpeed': isoSpeed,
        'apertureF': apertureF,
        'shutterSpeedDenom': shutterSpeedDenom,
        'focalLengthMm': focalLengthMm,
        'whiteBalanceMode': whiteBalanceMode,
        'flashMode': flashMode,
        'artistName': artistName,
        'copyright': copyright,
        'timestampMode': timestampMode.name,
        'timestampOffsetDays': timestampOffsetDays,
        'enableGps': enableGps,
        'gpsLatitude': gpsLatitude,
        'gpsLongitude': gpsLongitude,
        'gpsAltitudeM': gpsAltitudeM,
        'gpsLocationName': gpsLocationName,
      };

  factory ExifProfileEntity.fromJson(Map<String, dynamic> json) {
    return ExifProfileEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String? ?? 'camera_alt',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      lensModel: json['lensModel'] as String?,
      software: json['software'] as String?,
      isoSpeed: json['isoSpeed'] as int?,
      apertureF: (json['apertureF'] as num?)?.toDouble(),
      shutterSpeedDenom: (json['shutterSpeedDenom'] as num?)?.toDouble(),
      focalLengthMm: (json['focalLengthMm'] as num?)?.toDouble(),
      whiteBalanceMode: json['whiteBalanceMode'] as int?,
      flashMode: json['flashMode'] as int?,
      artistName: json['artistName'] as String?,
      copyright: json['copyright'] as String?,
      timestampMode: TimestampMode.values.firstWhere(
        (e) => e.name == json['timestampMode'],
        orElse: () => TimestampMode.current,
      ),
      timestampOffsetDays: json['timestampOffsetDays'] as int? ?? 0,
      enableGps: json['enableGps'] as bool? ?? false,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      gpsAltitudeM: (json['gpsAltitudeM'] as num?)?.toDouble(),
      gpsLocationName: json['gpsLocationName'] as String? ?? '',
    );
  }

  /// Untuk import/export file JSON
  String exportJson() => jsonEncode(toJson());

  static ExifProfileEntity importJson(String jsonStr) {
    return ExifProfileEntity.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}

enum TimestampMode {
  current, // gunakan waktu sekarang
  random, // random dalam rentang offsetDays ke belakang
  fixed, // offset tepat offsetDays ke belakang
}

/// ── Built-in Profiles ────────────────────────────────────────────────────────

class BuiltInProfiles {
  static const List<ExifProfileEntity> all = [
    _clean,
    _iphone15pro,
    _samsungS24Ultra,
    _googlePixel9Pro,
    _sonyXperia1VI,
    _canonEosR6,
    _nikonZ8,
    _fujifilmXT5,
    _djiMini4Pro,
    _photoshop,
  ];

  static const ExifProfileEntity _clean = ExifProfileEntity(
    id: 'clean',
    name: 'Clean (Tanpa Metadata)',
    iconKey: 'cleaning_services',
    isBuiltIn: true,
  );

  static const ExifProfileEntity _iphone15pro = ExifProfileEntity(
    id: 'iphone15pro',
    name: 'Apple iPhone 15 Pro',
    iconKey: 'phone_iphone',
    isBuiltIn: true,
    cameraMake: 'Apple',
    cameraModel: 'iPhone 15 Pro',
    lensModel: 'iPhone 15 Pro back triple camera 6.765mm f/1.78',
    software: '17.5.1',
    isoSpeed: 100,
    apertureF: 1.78,
    shutterSpeedDenom: 120,
    focalLengthMm: 6.765,
    whiteBalanceMode: 0,
    flashMode: 16,
  );

  static const ExifProfileEntity _samsungS24Ultra = ExifProfileEntity(
    id: 'samsungS24Ultra',
    name: 'Samsung Galaxy S24 Ultra',
    iconKey: 'phone_android',
    isBuiltIn: true,
    cameraMake: 'samsung',
    cameraModel: 'SM-S928B',
    software: 'SM-S928BXXU1AXB5',
    isoSpeed: 50,
    apertureF: 1.7,
    shutterSpeedDenom: 180,
    focalLengthMm: 6.3,
    whiteBalanceMode: 0,
    flashMode: 16,
  );

  static const ExifProfileEntity _googlePixel9Pro = ExifProfileEntity(
    id: 'pixel9pro',
    name: 'Google Pixel 9 Pro',
    iconKey: 'phone_android',
    isBuiltIn: true,
    cameraMake: 'Google',
    cameraModel: 'Pixel 9 Pro',
    lensModel: 'rear',
    software: 'Pixel Experience 14',
    isoSpeed: 66,
    apertureF: 1.68,
    shutterSpeedDenom: 200,
    focalLengthMm: 6.0,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _sonyXperia1VI = ExifProfileEntity(
    id: 'sonyXperia1VI',
    name: 'Sony Xperia 1 VI',
    iconKey: 'camera',
    isBuiltIn: true,
    cameraMake: 'Sony',
    cameraModel: 'XQ-EC54',
    software: '65.2.A.0.404',
    isoSpeed: 125,
    apertureF: 1.9,
    shutterSpeedDenom: 250,
    focalLengthMm: 4.0,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _canonEosR6 = ExifProfileEntity(
    id: 'canonEosR6',
    name: 'Canon EOS R6 Mark II',
    iconKey: 'camera_alt',
    isBuiltIn: true,
    cameraMake: 'Canon',
    cameraModel: 'Canon EOS R6 Mark II',
    lensModel: 'RF 50mm F1.8 STM',
    software: 'Digital Photo Professional 4.22.30',
    isoSpeed: 400,
    apertureF: 2.8,
    shutterSpeedDenom: 500,
    focalLengthMm: 50.0,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _nikonZ8 = ExifProfileEntity(
    id: 'nikonZ8',
    name: 'Nikon Z8',
    iconKey: 'camera_alt',
    isBuiltIn: true,
    cameraMake: 'NIKON CORPORATION',
    cameraModel: 'NIKON Z 8',
    lensModel: 'NIKKOR Z 50mm f/1.8 S',
    software: 'Ver.1.30',
    isoSpeed: 200,
    apertureF: 2.0,
    shutterSpeedDenom: 640,
    focalLengthMm: 50.0,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _fujifilmXT5 = ExifProfileEntity(
    id: 'fujifilmXT5',
    name: 'Fujifilm X-T5',
    iconKey: 'camera_alt',
    isBuiltIn: true,
    cameraMake: 'FUJIFILM',
    cameraModel: 'X-T5',
    lensModel: 'XF23mmF1.4 R LM WR',
    software: 'Fujifilm X RAW STUDIO',
    isoSpeed: 160,
    apertureF: 2.0,
    shutterSpeedDenom: 400,
    focalLengthMm: 23.0,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _djiMini4Pro = ExifProfileEntity(
    id: 'djiMini4Pro',
    name: 'DJI Mini 4 Pro',
    iconKey: 'airplanemode_active',
    isBuiltIn: true,
    cameraMake: 'DJI',
    cameraModel: 'FC4582',
    software: '01.00.0500',
    isoSpeed: 100,
    apertureF: 1.7,
    shutterSpeedDenom: 1000,
    focalLengthMm: 4.5,
    whiteBalanceMode: 0,
    flashMode: 0,
  );

  static const ExifProfileEntity _photoshop = ExifProfileEntity(
    id: 'photoshop',
    name: 'Adobe Photoshop 2026',
    iconKey: 'brush',
    isBuiltIn: true,
    software: 'Adobe Photoshop 26.0 (Windows)',
    artistName: '',
    copyright: '',
  );
}
