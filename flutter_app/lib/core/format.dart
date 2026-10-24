// Number and date formatting. Western digits are used everywhere, like the web app.

/// Rounds to cents the same way the server does (Math.round(x * 100) / 100).
double roundMoney(double value) => (value * 100).roundToDouble() / 100;

/// 1234.5 becomes $1,234.5 (at most two decimals, no trailing zeros), like usd() in the web app.
String formatUsd(num value) {
  final double number = value.toDouble();
  if (number.isNaN || number.isInfinite) {
    return '\$0';
  }
  final bool negative = number < 0;
  final String fixed = number.abs().toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts[0];
  String decimals = parts.length > 1 ? parts[1] : '';
  while (decimals.endsWith('0')) {
    decimals = decimals.substring(0, decimals.length - 1);
  }
  final StringBuffer grouped = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final int remaining = whole.length - i;
    grouped.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      grouped.write(',');
    }
  }
  final String sign = negative ? '-' : '';
  final String fraction = decimals.isEmpty ? '' : '.$decimals';
  return '$sign\$$grouped$fraction';
}

/// dd/MM/yyyy, or a dash when the date is unknown.
String formatDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
