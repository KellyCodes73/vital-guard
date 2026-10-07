package com.vitalguard.monitoring.repository;

import com.vitalguard.monitoring.entity.MonitoringConfiguration;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MonitoringConfigurationRepository extends JpaRepository<MonitoringConfiguration, Long> {
    Optional<MonitoringConfiguration> findByUserId(Long userId);
}
