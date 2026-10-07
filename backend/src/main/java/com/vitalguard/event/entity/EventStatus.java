package com.vitalguard.event.entity;

public enum EventStatus {
    DETECTED,                 // detectado, esperando respuesta del usuario
    ATENDIDO_POR_USUARIO,     // el usuario pulsó "Estoy bien"
    NOTIFICADO_A_AUXILIADOR,  // sin respuesta: se creó la alerta para la persona de confianza
    SIN_AUXILIADOR,           // sin respuesta, pero no había persona de confianza vinculada
    CERRADO                   // cerrado (p. ej. cuando el auxiliador confirma recepción)
}
