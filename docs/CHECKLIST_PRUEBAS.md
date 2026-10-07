# Checklist de pruebas de punta a punta

Marcar cada punto con [x] cuando funcione. Resultado esperado entre paréntesis.

## Cuentas y sesión
- [ ] Registro de usuario monitoreado y de auxiliador (entra al Home de su rol)
- [ ] Contraseñas distintas / correo repetido (mensaje de error claro)
- [ ] Login correcto e incorrecto (incorrecto: "Credenciales inválidas")
- [ ] Cerrar sesión y volver a entrar; la sesión se restaura al reabrir la app

## Monitoreo
- [ ] Guardar horario y tiempo de espera (se conserva al reiniciar la sesión)
- [ ] Iniciar y detener monitoreo; cronómetro correcto; reabrir la app con monitoreo activo (sigue activo)
- [ ] Iniciar dos veces no crea dos sesiones

## Vinculación
- [ ] Invitar -> código de 6 dígitos -> el auxiliador acepta (pasa a "Vinculación activa" en ≤5 s)
- [ ] Código inválido (mensaje claro); cancelar invitación; revocar acceso (el auxiliador pierde la alerta)
- [ ] El auxiliador no puede usar endpoints del monitoreado (403)

## Flujo de alerta (modo demostración)
- [ ] Falsa alarma: "Patrón no confirmado", sin alerta
- [ ] Patrón + **ESTOY BIEN**: historial "Atendido por ti"
- [ ] Patrón sin responder, **con** persona de confianza: "Notificado", llega el aviso
- [ ] Patrón sin responder, **sin** persona de confianza: "Sin respuesta · no había persona de confianza"
- [ ] Auxiliador: ve nombre, hora, estado y ubicación; **Abrir ubicación** abre Google Maps
- [ ] **Confirmar recepción**: la alerta pasa a confirmada; el historial de Ana queda "Cerrado"
- [ ] La ubicación expira (probar con `ALERT_LOCATION_WINDOW_MINUTES=1`)

## Notificaciones (teléfono del auxiliador)
- [ ] Push con la app en segundo plano; push con la app cerrada; al tocarla abre la alerta
- [ ] Log del backend: `Push FCM enviado`; tabla `notifications`: `FCM` / `SENT`
- [ ] Al cerrar sesión el teléfono deja de recibir avisos de esa cuenta

## Audio experimental
- [ ] Aviso de consentimiento del micrófono; el medidor de nivel responde al sonido
- [ ] Silencio sin sonido previo: sin alerta
- [ ] Sonido rítmico ~20 s + silencio ~8 s: "Posible patrón detectado" y alerta
- [ ] Tras una detección el análisis se pausa 90 s

## Red y entorno
- [ ] Teléfono por Wi-Fi: Login -> Servidor -> Probar (conexión correcta) -> Guardar
- [ ] Prueba con el hotspot como plan B
- [ ] `flutter analyze` sin errores; `flutter test` en verde
