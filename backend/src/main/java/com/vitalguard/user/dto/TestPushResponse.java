package com.vitalguard.user.dto;

/** Resultado de la notificación de prueba que el usuario se envía a su propio teléfono. */
public record TestPushResponse(boolean sent, String channel, String message) {
}
