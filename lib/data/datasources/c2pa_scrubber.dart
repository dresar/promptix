import 'dart:typed_data';

/// Hasil scan C2PA / provenance
class C2paScanResult {
  final bool hasC2pa;
  final List<String> removedChunks;
  final Uint8List cleanBytes;

  const C2paScanResult({
    required this.hasC2pa,
    required this.removedChunks,
    required this.cleanBytes,
  });
}

/// Menghapus tanda C2PA, XMP, dan provenance AI dari file gambar
/// di level byte — sebelum decode — sehingga bahkan tools yang membaca
/// raw bytes pun tidak akan menemukan tanda AI.
///
/// Referensi format:
///  - JPEG: APP markers (FFEx FF EE dst), APP1=EXIF/XMP, APP11=JUMBF/C2PA, APP13=IPTC
///  - PNG: chunks 4-byte name, 4-byte length, data, 4-byte CRC
class C2paScrubber {
  /// Kata kunci AI yang dikenal (untuk deteksi signature)
  static const List<String> _aiKeywords = [
    'midjourney',
    'dall-e',
    'dall·e',
    'stable diffusion',
    'adobe firefly',
    'firefly',
    'kling',
    'runway',
    'leonardo',
    'pika',
    'ideogram',
    'adobe ai',
    'generative fill',
    'ai generated',
    'ai-generated',
    'artificial intelligence',
    'flux',
    'sora',
    'imagen',
    'wuerstchen',
    'dreamstudio',
    'nightcafe',
    'civitai',
    'novelai',
    'holara',
    'getimg',
    'playground ai',
  ];

  /// Software signatures yang dikenal sebagai AI generator
  static const List<String> _aiSoftwareSignatures = [
    'midjourney',
    'dall-e',
    'stable diffusion',
    'diffusion',
    'firefly',
    'kling',
    'runway ml',
    'leonardo ai',
    'pika labs',
    'ideogram',
    'flux',
    'automatic1111',
    'a1111',
    'comfyui',
    'invokeai',
    'fooocus',
    'dream',
    'imagineart',
    'ai generator',
  ];

  /// Proses utama: scan + strip bytes JPEG atau PNG
  static C2paScanResult scrub(Uint8List inputBytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'jpg' || ext == 'jpeg') {
      return _scrubJpeg(inputBytes);
    } else if (ext == 'png') {
      return _scrubPng(inputBytes);
    } else if (ext == 'webp') {
      return _scrubWebp(inputBytes);
    }
    return C2paScanResult(
      hasC2pa: false,
      removedChunks: [],
      cleanBytes: inputBytes,
    );
  }

  /// Deteksi keyword AI dari string metadata mentah
  static ({String? software, List<String> keywords}) detectAiSignature(
    Uint8List bytes,
  ) {
    final raw = String.fromCharCodes(bytes.take(65536)).toLowerCase();
    final found = <String>[];

    for (final kw in _aiKeywords) {
      if (raw.contains(kw)) found.add(kw);
    }

    String? detectedSoftware;
    for (final sw in _aiSoftwareSignatures) {
      if (raw.contains(sw)) {
        // Capitalize first letter
        detectedSoftware =
            sw.substring(0, 1).toUpperCase() + sw.substring(1);
        break;
      }
    }

    return (software: detectedSoftware, keywords: found);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JPEG Scrubber
  // ─────────────────────────────────────────────────────────────────────────

  static C2paScanResult _scrubJpeg(Uint8List bytes) {
    final removed = <String>[];
    final output = <int>[];
    bool hasC2pa = false;

    // JPEG starts with FF D8
    if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return C2paScanResult(
        hasC2pa: false,
        removedChunks: [],
        cleanBytes: bytes,
      );
    }

    output.add(0xFF);
    output.add(0xD8);

    int i = 2;
    while (i < bytes.length) {
      if (i + 1 >= bytes.length) break;

      // Look for FF marker
      if (bytes[i] != 0xFF) {
        // We're in scan data (after SOS), copy rest verbatim
        output.addAll(bytes.sublist(i));
        break;
      }

      final marker = bytes[i + 1];

      // Standalone markers with no length (SOI, EOI, SOS handled separately)
      if (marker == 0xD8 || marker == 0xD9) {
        output.add(0xFF);
        output.add(marker);
        i += 2;
        continue;
      }

      // SOS — beginning of compressed image data, copy rest
      if (marker == 0xDA) {
        output.addAll(bytes.sublist(i));
        break;
      }

      if (i + 3 >= bytes.length) break;
      final length = (bytes[i + 2] << 8) | bytes[i + 3]; // includes the 2 length bytes
      final segEnd = i + 2 + length;

      if (segEnd > bytes.length) {
        // Malformed: copy remainder
        output.addAll(bytes.sublist(i));
        break;
      }

      final segData = bytes.sublist(i + 4, segEnd);

      // APP1 (0xE1) → EXIF or XMP
      if (marker == 0xE1) {
        final header = _segHeader(segData);
        if (header.contains('exif')) {
          // Keep EXIF (we'll overwrite it via image package) — still scan
          final rawStr = String.fromCharCodes(segData).toLowerCase();
          if (_containsC2paKeyword(rawStr)) {
            hasC2pa = true;
            removed.add('APP1-EXIF(C2PA)');
            // Skip this segment
            i = segEnd;
            continue;
          }
        } else if (header.contains('http://ns.adobe.com/xmp') ||
            header.contains('xpacket') ||
            header.contains('w3.org/1999/02/22-rdf')) {
          final rawStr = String.fromCharCodes(segData).toLowerCase();
          if (_containsC2paKeyword(rawStr)) {
            hasC2pa = true;
          }
          // Always strip XMP
          removed.add('APP1-XMP');
          i = segEnd;
          continue;
        }
      }

      // APP11 (0xEB) → JUMBF / C2PA content credentials
      if (marker == 0xEB) {
        hasC2pa = true;
        removed.add('APP11-JUMBF(C2PA)');
        i = segEnd;
        continue;
      }

      // APP13 (0xED) → IPTC / Photoshop IRB (also carries C2PA sometimes)
      if (marker == 0xED) {
        final rawStr = String.fromCharCodes(segData).toLowerCase();
        if (_containsC2paKeyword(rawStr)) {
          hasC2pa = true;
          removed.add('APP13-IPTC(C2PA)');
        } else {
          removed.add('APP13-IPTC');
        }
        i = segEnd;
        continue;
      }

      // APP14 (0xEE) → Adobe (color space marker, harmless but contains "Adobe")
      if (marker == 0xEE) {
        removed.add('APP14-Adobe');
        i = segEnd;
        continue;
      }

      // APP15 (0xEF) → sometimes used for provenance
      if (marker == 0xEF) {
        removed.add('APP15');
        i = segEnd;
        continue;
      }

      // COM (0xFE) → Comments — strip, may contain AI info
      if (marker == 0xFE) {
        final comment = String.fromCharCodes(segData).toLowerCase();
        if (_aiKeywords.any((k) => comment.contains(k))) {
          removed.add('COM-comment(AI)');
          i = segEnd;
          continue;
        }
      }

      // Copy everything else verbatim
      output.add(0xFF);
      output.add(marker);
      output.add(bytes[i + 2]);
      output.add(bytes[i + 3]);
      output.addAll(segData);
      i = segEnd;
    }

    return C2paScanResult(
      hasC2pa: hasC2pa,
      removedChunks: removed,
      cleanBytes: Uint8List.fromList(output),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PNG Scrubber
  // ─────────────────────────────────────────────────────────────────────────

  static C2paScanResult _scrubPng(Uint8List bytes) {
    // PNG signature: 8 bytes
    const pngSig = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8) {
      return C2paScanResult(
        hasC2pa: false,
        removedChunks: [],
        cleanBytes: bytes,
      );
    }

    final removed = <String>[];
    bool hasC2pa = false;
    final output = <int>[];

    // Copy PNG signature
    output.addAll(pngSig);
    int i = 8;

    while (i < bytes.length) {
      if (i + 8 > bytes.length) break;

      final length = _readInt32(bytes, i);
      final chunkType = String.fromCharCodes(bytes.sublist(i + 4, i + 8));
      final chunkEnd = i + 12 + length; // 4 len + 4 type + data + 4 crc

      if (chunkEnd > bytes.length) break;

      final chunkData = length > 0
          ? bytes.sublist(i + 8, i + 8 + length)
          : Uint8List(0);

      // tEXt, iTXt, zTXt — text metadata, may contain AI info / XMP
      if (chunkType == 'tEXt' ||
          chunkType == 'iTXt' ||
          chunkType == 'zTXt') {
        final raw = String.fromCharCodes(chunkData).toLowerCase();
        if (_containsC2paKeyword(raw) || raw.contains('xmp')) {
          hasC2pa = true;
          removed.add('$chunkType(C2PA)');
        } else if (_aiKeywords.any((k) => raw.contains(k))) {
          removed.add('$chunkType(AI-kw)');
        } else {
          removed.add(chunkType);
        }
        i = chunkEnd;
        continue;
      }

      // eXIf — PNG EXIF chunk
      if (chunkType == 'eXIf') {
        final raw = String.fromCharCodes(chunkData).toLowerCase();
        if (_containsC2paKeyword(raw)) {
          hasC2pa = true;
          removed.add('eXIf(C2PA)');
        } else {
          removed.add('eXIf');
        }
        i = chunkEnd;
        continue;
      }

      // caBX / c2pa — explicit C2PA chunks
      if (chunkType == 'caBX' || chunkType == 'c2pa' || chunkType == 'JUMB') {
        hasC2pa = true;
        removed.add('$chunkType(C2PA)');
        i = chunkEnd;
        continue;
      }

      // Copy chunk verbatim
      output.addAll(bytes.sublist(i, chunkEnd));
      i = chunkEnd;
    }

    return C2paScanResult(
      hasC2pa: hasC2pa,
      removedChunks: removed,
      cleanBytes: Uint8List.fromList(output),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WebP Scrubber (basic — strip XMP chunk)
  // ─────────────────────────────────────────────────────────────────────────

  static C2paScanResult _scrubWebp(Uint8List bytes) {
    // WebP: RIFF....WEBP
    if (bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
      return C2paScanResult(
        hasC2pa: false,
        removedChunks: [],
        cleanBytes: bytes,
      );
    }

    final removed = <String>[];
    bool hasC2pa = false;
    final output = <int>[];

    // Copy RIFF header (12 bytes)
    output.addAll(bytes.sublist(0, 12));
    int i = 12;

    while (i + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(i, i + 4));
      final chunkSize = _readInt32Le(bytes, i + 4);
      final chunkEnd = i + 8 + chunkSize + (chunkSize % 2); // padding

      if (chunkEnd > bytes.length) break;

      // XMP chunk
      if (chunkId == 'XMP ') {
        final raw =
            String.fromCharCodes(bytes.sublist(i + 8, i + 8 + chunkSize))
                .toLowerCase();
        if (_containsC2paKeyword(raw)) hasC2pa = true;
        removed.add('WebP-XMP');
        i = chunkEnd;
        continue;
      }

      // EXIF chunk
      if (chunkId == 'EXIF') {
        removed.add('WebP-EXIF');
        i = chunkEnd;
        continue;
      }

      output.addAll(bytes.sublist(i, chunkEnd));
      i = chunkEnd;
    }

    // Fix RIFF file size
    final totalSize = output.length - 8;
    output[4] = totalSize & 0xFF;
    output[5] = (totalSize >> 8) & 0xFF;
    output[6] = (totalSize >> 16) & 0xFF;
    output[7] = (totalSize >> 24) & 0xFF;

    return C2paScanResult(
      hasC2pa: hasC2pa,
      removedChunks: removed,
      cleanBytes: Uint8List.fromList(output),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static String _segHeader(Uint8List data) {
    final preview = data.length > 64 ? data.sublist(0, 64) : data;
    return String.fromCharCodes(preview).toLowerCase();
  }

  static bool _containsC2paKeyword(String raw) {
    return raw.contains('c2pa') ||
        raw.contains('c2ma') ||
        raw.contains('content credentials') ||
        raw.contains('contentcredentials') ||
        raw.contains('jumbf') ||
        raw.contains('cai.') ||
        raw.contains('adobe.com/xap/1.0/') ||
        raw.contains('provenance');
  }

  static int _readInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static int _readInt32Le(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
