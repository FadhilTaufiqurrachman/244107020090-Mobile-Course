/// Fungsi murni (pure function) untuk formatting tanggal secara konsisten
/// tanpa bergantung pada widget atau BuildContext.
String formatDateIndo(DateTime dateTime) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = months[dateTime.month - 1];
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$day $month $year, $hour:$minute WIB';
}

/// Fungsi murni untuk mem-parsing dan mengekstrak rute dari payload notifikasi
/// tanpa ketergantungan pada Flutter widget tree atau plugin Firebase.
String parseRouteFromMessage(Map<String, dynamic> data) {
  final rawRoute = data['route']?.toString().trim() ?? '';
  if (rawRoute.isEmpty) return '/';
  return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
}
