package com.vitalguard.monitoring.dto;

import com.vitalguard.monitoring.entity.MonitoringConfiguration;
import java.time.format.DateTimeFormatter;

public record MonitoringConfigResponse(String startTime, String endTime,
                                       boolean scheduledEnabled, int alertTimeoutSeconds) {

    private static final DateTimeFormatter HM = DateTimeFormatter.ofPattern("HH:mm");

    public static MonitoringConfigResponse from(MonitoringConfiguration c) {
        return new MonitoringConfigResponse(
                c.getStartTime().format(HM),
                c.getEndTime().format(HM),
                c.isScheduledEnabled(),
                c.getAlertTimeoutSeconds());
    }
}
