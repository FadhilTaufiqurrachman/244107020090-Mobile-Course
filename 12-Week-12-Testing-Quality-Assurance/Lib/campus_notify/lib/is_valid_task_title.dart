/// Memvalidasi apakah judul tugas valid (berisi teks setelah spasi di awal dan akhir diabaikan).
bool isValidTaskTitle(String value) {
  return value.trim().isNotEmpty;
}

/// Validasi lanjutan dengan batasan panjang karakter untuk menguji kasus batas/tepi (edge cases).
bool isValidTaskTitleStrict(
  String value, {
  int minLength = 3,
  int maxLength = 100,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  return trimmed.length >= minLength && trimmed.length <= maxLength;
}

