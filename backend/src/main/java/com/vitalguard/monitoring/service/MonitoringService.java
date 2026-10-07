package com.vitalguard.monitoring.service;

import com.vitalguard.common.NotFoundException;
import com.vitalguard.monitoring.dto.MonitoringConfigResponse;
import com.vitalguard.monitoring.dto.SessionResponse;
import com.vitalguard.monitoring.dto.UpdateMonitoringConfigRequest;
import com.vitalguard.monitoring.entity.MonitoringConfiguration;
import com.vitalguard.monitoring.entity.MonitoringSession;
import com.vitalguard.monitoring.entity.SessionStatus;
import com.vitalguard.monitoring.repository.MonitoringConfigurationRepository;
import com.vitalguard.monitoring.repository.MonitoringSessionRepository;
import com.vitalguard.user.repository.UserRepository;
import java.time.Instant;
import java.time.LocalTime;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MonitoringService {

    private final MonitoringConfigurationRepository configRepository;
    private final MonitoringSessionRepository sessionRepository;
    private final UserRepository userRepository;

    public MonitoringService(MonitoringConfigurationRepository configRepository,
                             MonitoringSessionRepository sessionRepository,
                             UserRepository userRepository) {
        this.configRepository = configRepository;
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
    }

    // ---------- configuración ----------

    @Transactional
    public MonitoringConfigResponse getConfig(Long userId) {
        return MonitoringConfigResponse.from(findOrCreateConfig(userId));
    }

    @Transactional
    public MonitoringConfigResponse updateConfig(Long userId, UpdateMonitoringConfigRequest req) {
        MonitoringConfiguration config = findOrCreateConfig(userId);
        config.setStartTime(LocalTime.parse(req.startTime()));
        config.setEndTime(LocalTime.parse(req.endTime()));
        config.setScheduledEnabled(req.scheduledEnabled());
        config.setAlertTimeoutSeconds(req.alertTimeoutSeconds());
        return MonitoringConfigResponse.from(configRepository.save(config));
    }

    private MonitoringConfiguration findOrCreateConfig(Long userId) {
        return configRepository.findByUserId(userId).orElseGet(() -> {
            MonitoringConfiguration c = new MonitoringConfiguration();
            c.setUser(userRepository.getReferenceById(userId));
            c.setStartTime(LocalTime.of(23, 0));
            c.setEndTime(LocalTime.of(7, 0));
            c.setScheduledEnabled(false);
            c.setAlertTimeoutSeconds(30);
            return configRepository.save(c);
        });
    }

    // ---------- sesiones ----------

    /** Si ya hay un monitoreo activo, lo devuelve en lugar de crear otro. */
    @Transactional
    public SessionResponse start(Long userId, boolean demoMode) {
        Optional<MonitoringSession> active = sessionRepository
                .findFirstByUserIdAndStatusOrderByStartedAtDesc(userId, SessionStatus.ACTIVE);
        if (active.isPresent()) {
            return SessionResponse.from(active.get());
        }
        MonitoringSession session = new MonitoringSession();
        session.setUser(userRepository.getReferenceById(userId));
        session.setStartedAt(Instant.now());
        session.setStatus(SessionStatus.ACTIVE);
        session.setDemoMode(demoMode);
        return SessionResponse.from(sessionRepository.save(session));
    }

    @Transactional
    public SessionResponse stop(Long userId, Long sessionId) {
        MonitoringSession session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new NotFoundException("Sesión de monitoreo no encontrada"));
        if (session.getStatus() == SessionStatus.ACTIVE) {
            session.setStatus(SessionStatus.STOPPED);
            session.setEndedAt(Instant.now());
            session = sessionRepository.save(session);
        }
        return SessionResponse.from(session);
    }

    @Transactional(readOnly = true)
    public Optional<SessionResponse> getActive(Long userId) {
        return sessionRepository
                .findFirstByUserIdAndStatusOrderByStartedAtDesc(userId, SessionStatus.ACTIVE)
                .map(SessionResponse::from);
    }
}
