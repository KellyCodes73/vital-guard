package com.vitalguard.monitoring.repository;

import com.vitalguard.monitoring.entity.MonitoringSession;
import com.vitalguard.monitoring.entity.SessionStatus;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MonitoringSessionRepository extends JpaRepository<MonitoringSession, Long> {
    Optional<MonitoringSession> findFirstByUserIdAndStatusOrderByStartedAtDesc(Long userId, SessionStatus status);
    Optional<MonitoringSession> findByIdAndUserId(Long id, Long userId);
}
