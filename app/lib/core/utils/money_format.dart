import 'package:intl/intl.dart';

final _vndFormat = NumberFormat.decimalPattern('vi_VN');

/// [amountMinor] theo đơn vị nhỏ nhất (vd VND = đồng).
String formatMoneyVnd(int amountMinor) => '${_vndFormat.format(amountMinor)} đ';
