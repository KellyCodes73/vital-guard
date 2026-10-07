# Guion de exposición – Vital Guard

> Vital Guard es una herramienta de **apoyo preventivo**. **No diagnostica** ni reemplaza la atención médica.
> Siempre decir: "posible patrón respiratorio inusual" (nunca "detecta apnea").

## 1. Material
- PC con PostgreSQL y el backend encendido.
- **Teléfono Android** con la app instalada (usuario monitoreado: Ana).
- **Auxiliador (Kelly)**: lo ideal es un **segundo teléfono** (se ve el push real). Si no hay, usar Chrome en la PC (`http://localhost:5000`, alerta en ≤5 s).
- Todos los dispositivos en la **misma red Wi-Fi** (o el hotspot del teléfono).

## 2. Preparación (30 min antes)
1. Conectar la PC y el teléfono a la misma Wi-Fi. En la PC: `ipconfig` -> anotar la **Dirección IPv4** (ej. 192.168.18.35).
2. Abrir el puerto (PowerShell **Administrador**): `powershell -ExecutionPolicy Bypass -File .\scripts\abrir-firewall.ps1`
3. Encender el backend: `powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-backend.ps1 -Fcm`
   - Esperar `FCM habilitado...` y `Started VitalGuardApplication`.
4. En el teléfono: login -> botón **Servidor** -> escribir `http://IP_DE_LA_PC:8081` -> **Probar** (debe decir conexión correcta) -> **Guardar**.
5. Si el auxiliador va en Chrome: `cd mobile; flutter run -d web-server --web-port 5000` y abrir `http://localhost:5000`.
6. Comprobar: Ana y Kelly tienen **vinculación activa**; tiempo de espera de la alerta en **10 s**; permisos de notificaciones y ubicación concedidos; batería > 50 %; pantalla sin bloqueo automático corto.
7. Hacer **una prueba completa** (sección 4, pasos 5–7) antes de que llegue el público.

## 3. Guion (≈ 7 min)
| Min | Qué hacer | Qué decir |
|---|---|---|
| 0:00 | Pantalla de inicio / onboarding | El problema: eventos respiratorios durante el sueño pasan desapercibidos. Vital Guard **apoya la prevención**: monitorea, verifica, alerta y avisa a una persona de confianza. No diagnostica. |
| 0:45 | Login de Ana. Mostrar **Horario de sueño** | Configura su horario y cuánto tiempo tiene para responder antes de avisar a alguien. |
| 1:15 | **Persona de confianza** (Kelly vinculada) | Vinculación por **código** que expira; Ana puede **revocar** el acceso cuando quiera. |
| 1:45 | Home -> **Modo demostración** activado -> **INICIAR MONITOREO** | Aceptar el permiso de ubicación: se explica que solo se comparte **temporalmente** durante una alerta. |
| 2:15 | **Simular falsa alarma (ruido)** | La app **verifica** (persistencia, repetición, confianza, ruido) y la descarta: sigue monitoreando. |
| 2:45 | **Simular patrón inusual** -> alerta local -> **ESTOY BIEN** | Si el usuario responde, queda registrado como atendido y no se molesta a nadie. |
| 3:30 | **Simular patrón inusual** -> **no responder** | Al terminar la cuenta regresiva se crea la alerta. |
| 4:00 | **Auxiliador**: llega la notificación -> abrir | Ve la hora, el estado y la **ubicación temporal**. Botón **Abrir ubicación** (Google Maps). Explicar que no tiene acceso permanente. |
| 4:45 | **CONFIRMAR RECEPCIÓN** -> en Ana abrir **Historial** | El evento queda **Cerrado**. Todo queda registrado. |
| 5:15 | (Opcional) **Modo experimental** con micrófono | Apagar demo. Hacer un sonido rítmico suave ~20 s y luego silencio: se detecta un posible patrón. Es una **heurística experimental**, no un modelo clínico. |
| 6:00 | Privacidad | El audio se analiza **en el teléfono**; **no se guarda ni se envía**. Ubicación temporal. Contraseñas cifradas. Roles y revocación. |
| 6:30 | Limitaciones y futuro | Ver sección 5. |

## 4. Plan B (si algo falla)
| Problema | Solución rápida |
|---|---|
| El teléfono no conecta | Login -> **Servidor** -> **Probar**. Verificar IP (`ipconfig`), misma red, puerto abierto (abrir-firewall.ps1). |
| La red del lugar bloquea dispositivos entre sí | Usar el **hotspot del teléfono del auxiliador** (PC conectada a él) o conectar por **cable**: `adb reverse tcp:8081 tcp:8081` y en Servidor usar `http://localhost:8081`. |
| No llega el push | El auxiliador con la app abierta recibe la alerta por consulta cada 5 s. Revisar el log del backend (`Push FCM enviado`). |
| Falla el micrófono / hay mucho ruido | Quedarse en **modo demostración** (es el camino fiable). |
| El backend se cayó | Reiniciar con `iniciar-backend.ps1 -Fcm` (la base de datos conserva todo). |
| Se perdió la sesión | Volver a iniciar sesión (Ana / Kelly). |

## 5. Limitaciones y trabajo futuro (decirlo con honestidad)
- El análisis experimental es una **heurística** (energía y silencios): puede dar falsos positivos/negativos. Siguiente paso: **modelo TensorFlow Lite validado con especialistas**.
- Solo funciona con la app abierta y la pantalla encendida (falta un servicio en segundo plano).
- Comunicación HTTP de desarrollo: producción requiere **HTTPS**.
- Un solo auxiliador por usuario; escalamiento a varios y llamadas a emergencias quedan fuera del MVP.
- Pendiente revisar cumplimiento legal de protección de datos personales (p. ej. Ley 29733 en Perú) y consentimiento informado.
- Posibles mejoras: smartwatch (SpO2, frecuencia cardiaca), verificación en el servidor si la app se cierra durante la cuenta regresiva.

## 6. Al terminar
- Cerrar el puerto: `powershell -ExecutionPolicy Bypass -File .\scripts\cerrar-firewall.ps1` (Administrador).
