package com.vitalguard.alert.dto;

import com.vitalguard.location.entity.LocationSnapshot;
import java.time.Instant;

public record LocationResponse(double latitude, double longitude, Double accuracyMeters,
                               Instant capturedAt, Instant expiresAt) {

    public static LocationResponse from(LocationSnapshot s) {
        return new LocationResponse(s.getLatitude(), s.getLongitude(), s.getAccuracyMeters(),
                s.getCapturedAt(), s.getExpiresAt());
    }
}
