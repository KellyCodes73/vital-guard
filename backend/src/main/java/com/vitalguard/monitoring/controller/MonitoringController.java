package com.vitalguard.monitoring.controller;

import com.vitalguard.monitoring.dto.MonitoringConfigResponse;
import com.vitalguard.monitoring.dto.SessionResponse;
import com.vitalguard.monitoring.dto.StartMonitoringRequest;
import com.vitalguard.monitoring.dto.UpdateMonitoringConfigRequest;
import com.vitalguard.monitoring.service.MonitoringService;
import com.vitalguard.security.AuthenticatedUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Solo el usuario monitoreado puede configurar e iniciar monitoreos. */
@RestController
@RequestMapping("/api/monitoring")
@PreAuthorize("hasRole('MONITORED')")
public class MonitoringController {

    private final MonitoringService monitoringService;

    public MonitoringController(MonitoringService monitoringService) {
        this.monitoringService = monitoringService;
    }

    @GetMapping("/config")
    public MonitoringConfigResponse getConfig(@AuthenticationPrincipal AuthenticatedUser principal) {
        return monitoringService.getConfig(principal.id());
    }

    @PutMapping("/config")
    public MonitoringConfigResponse updateConfig(@AuthenticationPrincipal AuthenticatedUser principal,
                                                 @Valid @RequestBody UpdateMonitoringConfigRequest request) {
        return monitoringService.updateConfig(principal.id(), request);
    }

    @PostMapping("/start")
    public SessionResponse start(@AuthenticationPrincipal AuthenticatedUser principal,
                                 @RequestBody(required = false) StartMonitoringRequest request) {
        boolean demo = request == null || request.demoMode() == null || request.demoMode();
        return monitoringService.start(principal.id(), demo);
    }

    @PostMapping("/{id}/stop")
    public SessionResponse stop(@AuthenticationPrincipal AuthenticatedUser principal,
                                @PathVariable Long id) {
        return monitoringService.stop(principal.id(), id);
    }

    /** 200 con la sesión activa, o 204 si no hay ninguna. */
    @GetMapping("/active")
    public ResponseEntity<SessionResponse> active(@AuthenticationPrincipal AuthenticatedUser principal) {
        return monitoringService.getActive(principal.id())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }
}
