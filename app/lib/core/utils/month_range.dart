/// [d] bất kỳ trong tháng → ngày 1 của tháng đó.
DateTime firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

/// Ngày cuối cùng của tháng chứa [d].
DateTime lastDayOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

/// Định dạng `YYYY-MM-DD` cho cột `date` / `timestamptz` (phần ngày).
String toPgDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String monthLabelVi(DateTime month) =>
    'Tháng ${month.month}/${month.year}';
