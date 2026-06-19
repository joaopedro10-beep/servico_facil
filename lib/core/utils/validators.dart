class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Informe seu e-mail';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe uma senha';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirme sua senha';
    if (value != password) return 'As senhas não coincidem';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu nome';
    if (value.trim().length < 3) return 'Nome muito curto';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Informe seu telefone';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Este campo'}) {
    if (value == null || value.trim().length < min) {
      return '$field deve ter pelo menos $min caracteres';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Informe o preço por hora';
    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null || price <= 0) return 'Preço inválido';
    return null;
  }

}
