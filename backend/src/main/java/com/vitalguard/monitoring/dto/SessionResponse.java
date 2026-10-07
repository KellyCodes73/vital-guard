package com.vitalguard.monitoring.dto;

import com.vitalguard.monitoring.entity.MonitoringSession;
import com.vitalguard.monitoring.entity.SessionStatus;
import java.time.Instant;

public record SessionResponse(Long id, Instant startedAt, Instant endedAt,
                              SessionStatus status, boolean demoMode) {

    public static SessionResponse from(MonitoringSession s) {
        return new SessionResponse(s.getId(), s.getStartedAt(), s.getEndedAt(), s.getStatus(), s.isDemoMode());
    }
}
