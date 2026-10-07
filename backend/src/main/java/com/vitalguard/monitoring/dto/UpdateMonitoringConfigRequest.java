package com.vitalguard.monitoring.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record UpdateMonitoringConfigRequest(
        @NotBlank @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$", message = "debe tener formato HH:mm") String startTime,
        @NotBlank @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$", message = "debe tener formato HH:mm") String endTime,
        @NotNull Boolean scheduledEnabled,
        @NotNull @Min(10) @Max(300) Integer alertTimeoutSeconds) {
}
