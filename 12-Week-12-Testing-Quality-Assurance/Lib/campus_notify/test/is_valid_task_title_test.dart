import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle (Unit Test Dasar & Perilaku)', () {
    test('menerima judul yang berisi teks', () {
      // Arrange
      const validTitle = 'Belajar Flutter';

      // Act
      final result = isValidTaskTitle(validTitle);

      // Assert
      expect(result, isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      // Arrange & Act & Assert
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
    });

    test('menerima judul dengan spasi di awal dan akhir asalkan ada teks', () {
      // Arrange
      const titleWithPadding = '   Praktikum Testing   ';

      // Act
      final result = isValidTaskTitle(titleWithPadding);

      // Assert
      expect(result, isTrue);
    });

    test('menolak string yang hanya berisi tab dan newline (kasus tepi)', () {
      expect(isValidTaskTitle('\t\t'), isFalse);
      expect(isValidTaskTitle('\n\n\r'), isFalse);
      expect(isValidTaskTitle(' \t \n '), isFalse);
    });

    test('menerima judul yang mengandung angka, simbol, dan emoji', () {
      expect(isValidTaskTitle('Tugas #12: QA & Testing 🚀'), isTrue);
    });
  });

  group('isValidTaskTitleStrict (Kasus Batas / Boundary Value Analysis)', () {
    test('menolak jika panjang karakter kurang dari batas minimum (kasus tepi underflow)', () {
      // Arrange: batas min 3 karakter, input 2 karakter
      const shortTitle = 'AB';

      // Act
      final result = isValidTaskTitleStrict(shortTitle, minLength: 3);

      // Assert
      expect(result, isFalse);
    });

    test('menerima jika panjang karakter tepat pada batas minimum', () {
      // Arrange
      const boundaryMin = 'ABC';

      // Act
      final result = isValidTaskTitleStrict(boundaryMin, minLength: 3);

      // Assert
      expect(result, isTrue);
    });

    test('menerima jika panjang karakter tepat pada batas maksimum 100 karakter', () {
      // Arrange
      final exact100 = 'A' * 100;

      // Act
      final result = isValidTaskTitleStrict(exact100, maxLength: 100);

      // Assert
      expect(result, isTrue);
    });

    test('menolak jika panjang karakter melebihi batas maksimum (kasus tepi overflow)', () {
      // Arrange
      final overflow101 = 'A' * 101;

      // Act
      final result = isValidTaskTitleStrict(overflow101, maxLength: 100);

      // Assert
      expect(result, isFalse);
    });
  });
}

