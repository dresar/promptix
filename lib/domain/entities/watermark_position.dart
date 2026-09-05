enum WatermarkPositionType {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
  custom,
}

class WatermarkPosition {
  final WatermarkPositionType type;
  final double xPercent; // Used for custom offset (0.0 to 1.0)
  final double yPercent; // Used for custom offset (0.0 to 1.0)
  final double marginPaddingRatio; // Margin from borders (default 0.02 = 2%)

  const WatermarkPosition({
    this.type = WatermarkPositionType.bottomRight,
    this.xPercent = 0.02,
    this.yPercent = 0.02,
    this.marginPaddingRatio = 0.02,
  });

  String get label {
    switch (type) {
      case WatermarkPositionType.topLeft:
        return 'Pojok Kiri Atas';
      case WatermarkPositionType.topRight:
        return 'Pojok Kanan Atas';
      case WatermarkPositionType.bottomLeft:
        return 'Pojok Kiri Bawah';
      case WatermarkPositionType.bottomRight:
        return 'Pojok Kanan Bawah';
      case WatermarkPositionType.center:
        return 'Tengah (Center)';
      case WatermarkPositionType.custom:
        return 'Posisi Kustom';
    }
  }

  /// Menghasilkan filter expression koordinat FFmpeg overlay
  /// main_w, main_h = dimensi video/gambar utama
  /// overlay_w, overlay_h = dimensi logo/watermark
  String toFfmpegOverlayCoordinates() {
    final pad = marginPaddingRatio.toStringAsFixed(3);
    switch (type) {
      case WatermarkPositionType.topLeft:
        return 'x=main_w*$pad:y=main_h*$pad';
      case WatermarkPositionType.topRight:
        return 'x=main_w-overlay_w-main_w*$pad:y=main_h*$pad';
      case WatermarkPositionType.bottomLeft:
        return 'x=main_w*$pad:y=main_h-overlay_h-main_h*$pad';
      case WatermarkPositionType.bottomRight:
        return 'x=main_w-overlay_w-main_w*$pad:y=main_h-overlay_h-main_h*$pad';
      case WatermarkPositionType.center:
        return 'x=(main_w-overlay_w)/2:y=(main_h-overlay_h)/2';
      case WatermarkPositionType.custom:
        final x = xPercent.toStringAsFixed(3);
        final y = yPercent.toStringAsFixed(3);
        return 'x=(main_w-overlay_w)*$x:y=(main_h-overlay_h)*$y';
    }
  }

  /// Parse dari string nama posisi (misal: 'bottomRight')
  static WatermarkPosition fromString(String positionStr) {
    switch (positionStr) {
      case 'topLeft':
        return const WatermarkPosition(type: WatermarkPositionType.topLeft);
      case 'topRight':
        return const WatermarkPosition(type: WatermarkPositionType.topRight);
      case 'bottomLeft':
        return const WatermarkPosition(type: WatermarkPositionType.bottomLeft);
      case 'center':
        return const WatermarkPosition(type: WatermarkPositionType.center);
      case 'custom':
        return const WatermarkPosition(type: WatermarkPositionType.custom);
      case 'bottomRight':
      default:
        return const WatermarkPosition(type: WatermarkPositionType.bottomRight);
    }
  }

  String toPositionString() {
    switch (type) {
      case WatermarkPositionType.topLeft:
        return 'topLeft';
      case WatermarkPositionType.topRight:
        return 'topRight';
      case WatermarkPositionType.bottomLeft:
        return 'bottomLeft';
      case WatermarkPositionType.bottomRight:
        return 'bottomRight';
      case WatermarkPositionType.center:
        return 'center';
      case WatermarkPositionType.custom:
        return 'custom';
    }
  }
}
