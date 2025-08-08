# 🎥 Zoom Video SDK Flutter Demo

Este proyecto Flutter demuestra cómo integrar Zoom Video SDK para habilitar videollamadas, siguiendo el tutorial explicado en mi artículo de Medium:  
[Integrate Flutter with Zoom VideoCalling](https://medium.com/@darasat/integratar-flutter-zoom-videocalling-960dbec5b8f7)

## 📋 Descripción General

Esta aplicación utiliza el paquete `flutter_zoom_videosdk` para conectarse con el SDK nativo de Zoom, permitiendo a los usuarios unirse a sesiones de video autenticadas mediante JWT.

El artículo guía a través de todo el proceso — desde la configuración inicial, generación de JWT, hasta la implementación en Flutter.

## 🔧 Prerequisitos

- ✅ Flutter instalado ([Guía de instalación de Flutter](https://flutter.dev/docs/get-started/install))  
- ✅ Cuenta de desarrollador de Zoom con SDK Key y SDK Secret desde [Zoom Marketplace](https://marketplace.zoom.us/)  
- ✅ Permisos de cámara y micrófono configurados para Android e iOS  

## 🚀 Pasos Clave de Integración

### 1. Agregar Dependencias

Agrega estas dependencias a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  flutter_zoom_videosdk: ^1.14.0
  permission_handler: ^11.4.0
  dart_jsonwebtoken: ^2.13.0
```

### 2. Configurar Permisos

#### Android - AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS - Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>El acceso a la cámara es requerido para videollamadas.</string>
<key>NSMicrophoneUsageDescription</key>
<string>El acceso al micrófono es requerido para videollamadas.</string>
```

### 3. Generar JWT

El artículo incluye un ejemplo de generación de token JWT, que es necesario para la autenticación.

⚠️ **Para seguridad, genera este token en tu backend**, pero para pruebas, puedes generarlo localmente como sigue:

```dart
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String makeId(int length) {
  String result = '';
  const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rnd = Random();
  for (var i = 0; i < length; i++) {
    result += characters[rnd.nextInt(characters.length)];
  }
  return result;
}

String generateJwt(String sdkKey, String sdkSecret, String sessionName, int role) {
  final iat = DateTime.now();
  final exp = iat.add(const Duration(days: 2));
  final jwt = JWT({
    'app_key': sdkKey,
    'iat': (iat.millisecondsSinceEpoch / 1000).round(),
    'exp': (exp.millisecondsSinceEpoch / 1000).round(),
    'tpc': sessionName,
    'user_identity': makeId(10),
    'role_type': role, // 1: host, 2: participant
  });

  return jwt.sign(SecretKey(sdkSecret));
}
```

### 4. Usar Zoom SDK en Flutter

Ejemplo de `main.dart` mostrando cómo crear la vista de Zoom:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoom Video SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ZoomDemoPage(),
    );
  }
}

class ZoomDemoPage extends StatelessWidget {
  const ZoomDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom Video SDK Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_call,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Demo de Zoom Video SDK',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                zoom.ZoomView.create(
                  zoomViewOptions: zoom.ZoomViewOptions(
                    domain: 'zoom.us',
                    jwt: 'YOUR_GENERATED_JWT',
                    meetingNumber: 'MEETING_ID',
                    userName: 'DemoUser',
                    userId: '123456',
                    userType: zoom.ZoomUserType.ZoomUserTypeNormal,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Unirse a la Reunión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Reemplaza** `'YOUR_GENERATED_JWT'` y `'MEETING_ID'` con valores reales.

## 📁 Estructura del Proyecto

```
zoom_video_sdk_demo/
├── lib/
│   ├── main.dart              # Punto de entrada principal
│   ├── jwt_helper.dart        # Utilidades para JWT
│   └── zoom_meeting_page.dart # Página de reunión
├── android/
│   └── app/
│       └── src/main/
│           └── AndroidManifest.xml
├── ios/
│   └── Runner/
│       └── Info.plist
└── pubspec.yaml
```

## 🔧 Instalación y Configuración

1. **Clona el repositorio:**
   ```bash
   git clone <repository-url>
   cd zoom_video_sdk_demo
   ```

2. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configura tus credenciales de Zoom:**
   - Obtén tu SDK Key y SDK Secret desde [Zoom Marketplace](https://marketplace.zoom.us/)
   - Actualiza las variables en tu código

4. **Ejecuta la aplicación:**
   ```bash
   flutter run
   ```

## 🔐 Consideraciones de Seguridad

⚠️ **IMPORTANTE**: 
- Nunca hardcodees tus credenciales de Zoom en el código de producción
- Genera tokens JWT en tu backend servidor
- Valida siempre los permisos de usuario antes de generar tokens

## 🐛 Solución de Problemas

### Problemas Comunes:

**Error de permisos:**
- Asegúrate de que los permisos estén correctamente configurados en AndroidManifest.xml e Info.plist

**JWT inválido:**
- Verifica que tu SDK Key y Secret sean correctos
- Confirma que el token no haya expirado

**Falla de conexión:**
- Verifica tu conexión a internet
- Confirma que el Meeting ID sea válido

## 📚 Recursos Adicionales

- 📖 [Artículo completo en Medium](https://medium.com/@darasat/integratar-flutter-zoom-videocalling-960dbec5b8f7)
- 📖 [Documentación oficial de Zoom Video SDK](https://developers.zoom.us/docs/video-sdk/)
- 📦 [Paquete flutter_zoom_videosdk](https://pub.dev/packages/flutter_zoom_videosdk)
- 🔧 [Documentación de Flutter](https://flutter.dev/docs)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**@darasat**
- Medium: [@darasat](https://medium.com/@darasat)
- GitHub: [https://github.com/darasat]

---

⭐ Si este proyecto te fue útil, ¡no olvides darle una estrella!
