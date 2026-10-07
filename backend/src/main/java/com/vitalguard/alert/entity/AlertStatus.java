package com.vitalguard.alert.entity;

public enum AlertStatus {
    ACTIVE,        // creada, pendiente de que el auxiliador la reciba
    ACKNOWLEDGED,  // el auxiliador confirmó recepción
    CLOSED         // cerrada
}
