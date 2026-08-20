/// Relative / friendly time labels for lists & bubbles.
abstract final class RelativeTime {
  static String compact(DateTime at, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final local = at.toLocal();
    final diff = n.difference(local);

    if (diff.inSeconds < 45) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24 && _sameDay(local, n)) {
      return _hm(local);
    }
    if (diff.inHours < 48 && _yesterday(local, n)) return 'Yesterday';
    if (diff.inDays < 7) return _weekday(local);
    if (local.year == n.year) {
      return '${_month(local.month)} ${local.day}';
    }
    return '${_month(local.month)} ${local.day}, ${local.year}';
  }

  static String bubble(DateTime at) => _hm(at.toLocal());

  static String daySeparator(DateTime at, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final local = at.toLocal();
    if (_sameDay(local, n)) return 'Today';
    if (_yesterday(local, n)) return 'Yesterday';
    if (local.year == n.year) {
      return '${_weekday(local)}, ${_month(local.month)} ${local.day}';
    }
    return '${_month(local.month)} ${local.day}, ${local.year}';
  }

  static bool isNewDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year != y.year || x.month != y.month || x.day != y.day;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _yesterday(DateTime a, DateTime n) {
    final y = n.subtract(const Duration(days: 1));
    return _sameDay(a, y);
  }

  static String _hm(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final ap = h >= 12 ? 'PM' : 'AM';
    return '$hour12:$m $ap';
  }

  static String _weekday(DateTime t) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[t.weekday - 1];
  }

  static String _month(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }
}
