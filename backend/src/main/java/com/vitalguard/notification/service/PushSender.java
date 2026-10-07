package com.vitalguard.notification.service;

import java.util.Map;

/**
 * Abstracción del envío de notificaciones push.
 * Fase 7A: LoggingPushSender (simulado). Fase 7B: FcmPushSender (Firebase Cloud Messaging).
 */
public interface PushSender {

    /** Nombre del canal, p. ej. "LOG" o "FCM". */
    String channel();

    /** Devuelve true si se envió correctamente. */
    boolean send(String fcmToken, String title, String body, Map<String, String> data);
}
