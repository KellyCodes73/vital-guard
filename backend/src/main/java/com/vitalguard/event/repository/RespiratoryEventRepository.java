package com.vitalguard.event.repository;

import com.vitalguard.event.entity.RespiratoryEvent;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RespiratoryEventRepository extends JpaRepository<RespiratoryEvent, Long> {
    Optional<RespiratoryEvent> findByIdAndUserId(Long id, Long userId);
    List<RespiratoryEvent> findTop100ByUserIdOrderByDetectedAtDesc(Long userId);
}
