class TimeSlot {
  final DateTime start;
  final DateTime end;
  final String label;
  final bool isAvailable;
  final bool isPeak;
  final int? estimatedWaitMinutes;

  const TimeSlot({
    required this.start,
    required this.end,
    required this.label,
    required this.isAvailable,
    this.isPeak = false,
    this.estimatedWaitMinutes,
  });

  bool get isNow {
    final now = DateTime.now();
    return start.isBefore(now) && end.isAfter(now);
  }

  bool get isPast {
    final now = DateTime.now();
    return end.isBefore(now);
  }

  bool get isSoon {
    final now = DateTime.now();
    final diff = start.difference(now);
    return diff.inMinutes > 0 && diff.inMinutes < 30;
  }

  String get displayTime {
    final format = (start.minute == 0 || start.minute == 30)
        ? 'HH:mm'
        : 'HH:mm';
    return '${_formatTime(start, format)} - ${_formatTime(end, format)}';
  }

  String _formatTime(DateTime time, String format) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get relativeLabel {
    if (isNow) return 'Maintenant';
    if (isSoon) return 'Dans ${start.difference(DateTime.now()).inMinutes} min';
    if (isPast) return 'Passé';
    return displayTime;
  }
}
