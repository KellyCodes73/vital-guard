String two(int n) => n.toString().padLeft(2, '0');

/// 07:05
String formatHm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// 02/10/2026
String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

/// 01:02:03
String formatDuration(Duration d) =>
    '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
