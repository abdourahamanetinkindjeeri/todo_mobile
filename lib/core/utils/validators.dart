class Validators {
  static String? required(String? value, {String field = 'Champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field obligatoire';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, field: 'Email');
    if (requiredError != null) return requiredError;

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, field: 'Mot de passe');
    if (requiredError != null) return requiredError;

    if (value!.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }
}
