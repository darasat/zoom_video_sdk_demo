import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String makeId(int length) {
  String result = '';
  const String characters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  int charactersLength = characters.length;
  for (var i = 0; i < length; i++) {
    result += characters[Random().nextInt(charactersLength)];
  }
  return result;
}

const Map<String, String> configs = {
  'ZOOM_SDK_KEY': 'LupvplQS7aBS45VHTppkFCaabmb5n1rkP3gk',
  'ZOOM_SDK_SECRET': 'rCmikpDq95j6Mf1LokbPbLPuOiUME5lQXxII',
};

String generateJwt(String sessionName, String roleType) {
  try {
    final iat = DateTime.now();
    final exp = DateTime.now().add(const Duration(days: 2));
    final jwt = JWT({
      'app_key': configs['ZOOM_SDK_KEY'],
      'version': 1,
      'user_identity': makeId(10),
      'iat': (iat.millisecondsSinceEpoch / 1000).round(),
      'exp': (exp.millisecondsSinceEpoch / 1000).round(),
      'tpc': sessionName,
      'role_type': int.parse(roleType), // 1: Host, 2: User
      'cloud_recording_option': 1,
    });

    final token = jwt.sign(SecretKey(configs['ZOOM_SDK_SECRET']!));
    return token;
  } catch (e) {
    print(e);
    return '';
  }
}
