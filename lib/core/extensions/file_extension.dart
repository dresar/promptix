extension IntFileSize on int {
  String toReadableSize() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  double toMB() => this / (1024 * 1024);

  double toKB() => this / 1024;
}

extension DoublePercentage on double {
  String toPercentageString() => '${toStringAsFixed(1)}%';
}
