package com.vitalguard.alert.repository;

import com.vitalguard.alert.entity.Alert;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AlertRepository extends JpaRepository<Alert, Long> {
    Optional<Alert> findByEventId(Long eventId);
    Optional<Alert> findByIdAndHelperId(Long id, Long helperId);
    Optional<Alert> findByIdAndEventUserId(Long id, Long monitoredUserId);
    List<Alert> findTop20ByHelperIdOrderByCreatedAtDesc(Long helperId);
}
