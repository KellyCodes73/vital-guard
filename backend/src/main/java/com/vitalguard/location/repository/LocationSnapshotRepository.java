package com.vitalguard.location.repository;

import com.vitalguard.location.entity.LocationSnapshot;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LocationSnapshotRepository extends JpaRepository<LocationSnapshot, Long> {
    Optional<LocationSnapshot> findByAlertId(Long alertId);
}
