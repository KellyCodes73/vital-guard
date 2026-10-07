package com.vitalguard.alert.dto;

import com.vitalguard.alert.entity.AlertStatus;
import com.vitalguard.trustedcontact.dto.PersonSummary;
import java.time.Instant;

/**
 * Vista de una alerta para el auxiliador. Solo incluye lo necesario:
 * nombre de la persona, hora, estado y (si sigue vigente) la ubicación temporal.
 */
public record AlertResponse(Long id, AlertStatus status, Instant createdAt, Instant acknowledgedAt,
                            Instant eventDetectedAt, PersonSummary monitoredUser,
                            boolean locationAvailable, Instant locationExpiresAt,
                            LocationResponse location) {
}
