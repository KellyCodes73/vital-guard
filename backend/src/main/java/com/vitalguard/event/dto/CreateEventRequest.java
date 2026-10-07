package com.vitalguard.event.dto;

import com.vitalguard.event.entity.EventSource;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

public record CreateEventRequest(
        @NotNull Long sessionId,
        @NotNull @DecimalMin("0.0") @DecimalMax("1.0") Double confidence,
        @NotNull EventSource source) {
}
