import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_clean_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email accepte une adresse valide', () {
      expect(Validators.email('jeeri@example.com'), isNull);
    });

    test('email refuse une adresse invalide', () {
      expect(Validators.email('jeeri-example.com'), 'Email invalide');
    });

    test('password refuse un mot de passe trop court', () {
      expect(
        Validators.password('123'),
        'Le mot de passe doit contenir au moins 6 caractères',
      );
    });

    test('required refuse une valeur vide', () {
      expect(Validators.required('   ', field: 'Nom'), 'Nom obligatoire');
    });
  });
}
