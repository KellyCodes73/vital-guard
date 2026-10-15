# PROGRESS

## Completado
- Fase 1 (backend): esqueleto Spring Boot, módulos, excepciones globales, /api/health. Verificado.
- Fase 2 (backend): User + roles, registro/login BCrypt + JWT, /api/users/me. Verificado.
- Fase 3 (Flutter): tema, splash, onboarding, registro, login, home por rol, CORS de desarrollo. Verificado.
- Fase 4: configuración e inicio/fin de monitoreo (backend + app). Verificado.
- Fase 5: vinculación usuario monitoreado <-> auxiliador por código, revocación. Verificado.
- Fase 6: eventos, verificación (app), alerta local con cuenta regresiva, "Estoy bien", escalamiento, historial. Verificado.
- Fase 7A: vista del auxiliador, ubicación temporal, confirmar recepción. Verificado.
- Fase 7B: notificaciones push reales con FCM (app en segundo plano y cerrada). Verificado en teléfono Android.
- Fase 8: captura de micrófono + análisis experimental + verificación + alerta. Pruebas automáticas (6) y prueba en teléfono verificadas.

## En desarrollo
- Etapa E2: notificacion de alta prioridad para el auxiliador (canal nativo vital_guard_alerts con sonido de alarma, vibracion y ventana emergente) y boton 'Probar notificacion' (POST /api/users/me/test-push). Pendiente de verificar en teléfono.
- Etapa E1b: tras avisar a la persona de confianza (o tras ESTOY BIEN) la pantalla de alerta vuelve sola al monitoreo; la alarma sigue hasta DETENER ALARMA (vuelta automatica). Pendiente de verificar.
- Etapa E1: alarma sonora + vibracion al detectar un posible patron (se apaga con ESTOY BIEN), pausa de 10 min tras una alerta y tope de 3 alertas/hora. Pendiente de verificar. Sigue E2: notificacion con sonido/ventana emergente para el auxiliador.
- Despliegue en la nube (Render): backend + base de datos publicados (B) y Firebase en la nube (C) verificados. Falta D: apuntar el APK a la nube, cuentas de demostracion y probar el flujo con push.
- Fase 9: pantalla "Servidor" (cambiar la dirección del backend desde la app), scripts de ejecución, guion de exposición y checklist.
  Pendiente: probar el teléfono por Wi-Fi (sin cable) y recorrer docs/CHECKLIST_PRUEBAS.md.

## Pendiente
- Ensayo completo de la exposición (docs/GUION_EXPOSICION.md)
- Mejoras futuras: modelo TFLite validado, servicio en segundo plano, HTTPS, verificación en el servidor si la app se cierra
  durante la cuenta regresiva, varios auxiliadores, cumplimiento legal de datos personales.

## Errores conocidos
- Puerto 8080 ocupado en la laptop del equipo: se usa SERVER_PORT=8081.
- Versión firebase-admin fijada en 9.2.0 (no se pudo confirmar la última publicada).
- Aviso de Flutter: firebase_core aún usa Kotlin Gradle Plugin (sin impacto hoy).
- El análisis de audio solo funciona con la app en primer plano y la pantalla encendida (sin servicio en segundo plano).
- El analizador experimental es una heurística: puede dar falsos positivos/negativos (no es un modelo clínico).
- El monitoreo programado solo guarda el horario; no inicia solo (fuera del MVP).
- Código de invitación de 6 dígitos sin límite de intentos (mejorar en producción).
- Si se cierra la app durante la cuenta regresiva de una alerta, el evento queda en DETECTED (no se escala solo).
