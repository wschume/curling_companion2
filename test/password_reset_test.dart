import 'package:flutter_test/flutter_test.dart';
import 'package:curling_companion/main.dart';
import 'package:curling_companion/services/services.dart';

class RecordingAuth extends LocalAuthService {
  String? email, language;
  @override
  Future<void> sendPasswordResetEmail(String email, String languageCode) async {
    this.email = email;
    language = languageCode;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reset forwards email and language without signing in', () async {
    final service = RecordingAuth();
    final controller = AuthController(service);
    await controller.sendPasswordResetEmail('user@example.com', 'de');
    expect(service.email, 'user@example.com');
    expect(service.language, 'de');
    expect(service.currentUserId, isNull);
    controller.dispose();
  });
  test('local reset preserves existing session', () async {
    final service = LocalAuthService();
    await service.signIn('current@example.com', 'password');
    await service.sendPasswordResetEmail('other@example.com', 'en');
    expect(service.currentEmail, 'current@example.com');
  });
}
