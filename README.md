# Vital Guard 

Aplicación móvil de **apoyo preventivo** para el monitoreo de posibles eventos respiratorios durante el sueño.

## Ejecución rápida (Windows)
Desde la carpeta `vital-guard`:
```
powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-backend.ps1 -Fcm     # backend (sin -Fcm: notificaciones simuladas)
powershell -ExecutionPolicy Bypass -File .\scripts\abrir-firewall.ps1           # (Administrador) puerto 8081 para el teléfono
powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1            # construye e instala la app en el teléfono (USB)
```

## Arquitectura
Flutter (Android) ⇄ REST/JWT ⇄ Spring Boot ⇄ PostgreSQL · FCM para notificaciones.
El audio se procesa solo en el teléfono; al backend solo llegan eventos.

```
vital-guard/
  backend/   Spring Boot (Java 21, Maven)
  mobile/    Flutter (se crea con `flutter create`)
  docker-compose.yml
```

## Requisitos
- JDK 21, Maven 3.9+
- Docker (recomendado) o PostgreSQL 16 instalado
- Flutter SDK, Android Studio, teléfono Android real (más adelante)

## Instalación y ejecución (backend)
1. Base de datos: `docker compose up -d`
2. Backend: `cd backend && mvn spring-boot:run`
3. Probar: `curl http://localhost:8080/api/health`

## Variables de entorno
| Variable | Por defecto | Descripción |
|---|---|---|
| DB_URL | jdbc:postgresql://localhost:5432/vitalguard | URL JDBC |
| DB_USER | vitalguard | Usuario BD |
| DB_PASSWORD | vitalguard | Contraseña BD |
| JWT_SECRET | clave de desarrollo | Clave de firma JWT (mínimo 32 caracteres) |
| JWT_EXPIRATION_MINUTES | 1440 | Duración del token |
| SERVER_PORT | 8080 | Puerto del backend |

## App móvil (Flutter)
Crear el proyecto (una sola vez, desde la raíz `vital-guard/`):
```
flutter create --org com.vitalguard --project-name vital_guard --platforms android,web mobile
cd mobile
flutter pub add flutter_riverpod go_router dio flutter_secure_storage geolocator url_launcher
```
Luego se copia el código de `lib/` (el zip lo trae como `mobile_lib/`).

Ejecutar (con el backend encendido):
```
cd mobile
flutter run -d chrome                      # pruebas rápidas en el navegador
flutter run --dart-define=API_BASE_URL=http://IP_DE_TU_PC:8081   # teléfono real
```
La URL del backend se define en `lib/core/config/api_config.dart` (por defecto http://localhost:8081).
CORS está abierto solo para desarrollo en `SecurityConfig`.

## Notificaciones push (Firebase Cloud Messaging) - Fase 7B
Sin configurar nada, el backend usa notificaciones SIMULADAS (solo log) y el auxiliador ve las alertas consultando cada 5 s.
Para push reales:
1. Proyecto Firebase + app Android `com.vitalguard.vital_guard` -> `mobile/android/app/google-services.json` (no se sube a Git).
2. Cuenta de servicio (JSON) guardada FUERA del proyecto, p. ej. `%USERPROFILE%\vital-guard-secrets\firebase-service-account.json`.
3. Variables de entorno del backend:
```
$env:FCM_ENABLED = "true"
$env:FCM_SERVICE_ACCOUNT_PATH = "$HOME\vital-guard-secrets\firebase-service-account.json"
```
4. App: `flutter pub add firebase_core firebase_messaging`. El push solo funciona en Android (en el navegador se omite).

| Método | Ruta | Descripción |
|---|---|---|
| PUT | /api/users/me/fcm-token | Registra el token del teléfono (se le quita a otras cuentas) |
| DELETE | /api/users/me/fcm-token | Quita el token (al cerrar sesión) |

## Análisis de audio experimental - Fase 8
Dos modos al iniciar el monitoreo (interruptor "Modo demostración" en el Home):
- **Demostración** (activado): sin micrófono; botones que simulan un patrón o una falsa alarma.
- **Experimental** (apagado): usa el micrófono del teléfono.

Flujo: `AudioCaptureService` (paquete `record`, PCM16 16 kHz mono) -> `AudioPreprocessingService`
(tramos de 100 ms -> intensidad RMS, ventanas de 2 s; **el audio se descarta**) -> `RespiratoryAnalysisService`
(`ExperimentalEnergyAnalyzer`, heurística NO clínica: sonido de base + pausa prolongada) -> `EventVerificationService`
(persistencia, repetición, confianza, ruido) -> evento (`source=EXPERIMENTAL`) -> alerta local.

Privacidad: el audio no se guarda ni se envía; solo se calculan valores de intensidad en el teléfono.
Limitación: el análisis solo funciona con la app abierta y la pantalla encendida (se usa wakelock).
Para usar un modelo real (TensorFlow Lite / LiteRT) basta con implementar `RespiratoryAnalysisService`.

Dependencias: `flutter pub add record wakelock_plus`. Pruebas: `flutter test` (en `mobile/`).

## Despliegue en la nube (Render)
- `render.yaml` crea la base de datos PostgreSQL gratuita y el backend (Docker, `backend/Dockerfile`).
- URL: https://vitalguard-backend.onrender.com (salud: `/api/health`).
- Variables: `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD` (desde la base de datos), `JWT_SECRET` (generado), `FCM_ENABLED`,
  `FCM_SERVICE_ACCOUNT_PATH=/etc/secrets/firebase-service-account.json` (la credencial se sube como *Secret File*, nunca al repositorio).
- APK apuntando a la nube: `powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1 -ApiUrl https://vitalguard-backend.onrender.com`

