import 'package:intl/intl.dart';

class Formatter {
  static String formatCurrency(double amount) {
    return NumberFormat.simpleCurrency().format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
