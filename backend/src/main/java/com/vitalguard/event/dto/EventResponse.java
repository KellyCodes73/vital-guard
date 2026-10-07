package com.vitalguard.event.dto;

import com.vitalguard.event.entity.EventSource;
import com.vitalguard.event.entity.EventStatus;
import com.vitalguard.event.entity.RespiratoryEvent;
import java.time.Instant;

public record EventResponse(Long id, Long sessionId, Instant detectedAt, double confidence,
                            EventSource source, EventStatus status,
                            Instant resolvedAt, Instant escalatedAt, Long alertId) {

    public static EventResponse from(RespiratoryEvent e) {
        return from(e, null);
    }

    public static EventResponse from(RespiratoryEvent e, Long alertId) {
        return new EventResponse(e.getId(), e.getSession().getId(), e.getDetectedAt(), e.getConfidence(),
                e.getSource(), e.getStatus(), e.getResolvedAt(), e.getEscalatedAt(), alertId);
    }
}
