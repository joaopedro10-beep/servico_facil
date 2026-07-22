import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  static String dateTime(DateTime date) => DateFormat('dd/MM/yyyy  HH:mm').format(date);
  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';
    return AppFormatters.date(date);
  }

  static String currency(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);

  static String pricePerHour(double value) => '${currency(value)}/h';

  static String distance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String orderStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pendente';
      case 'accepted': return 'Aceito';
      case 'arrived': return 'Chegou ao local';
      case 'inProgress': return 'Em andamento';
      case 'done': return 'Concluído';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

}
