package com.vitalguard.alert.controller;

import com.vitalguard.alert.dto.AlertResponse;
import com.vitalguard.alert.dto.UpdateLocationRequest;
import com.vitalguard.alert.service.AlertService;
import com.vitalguard.security.AuthenticatedUser;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/alerts")
public class AlertController {

    private final AlertService alertService;

    public AlertController(AlertService alertService) {
        this.alertService = alertService;
    }

    /** Auxiliador: sus alertas recientes (sin coordenadas; solo si hay ubicación disponible). */
    @GetMapping
    @PreAuthorize("hasRole('HELPER')")
    public List<AlertResponse> list(@AuthenticationPrincipal AuthenticatedUser principal) {
        return alertService.listForHelper(principal.id());
    }

    /** Auxiliador: detalle con la ubicación temporal (si sigue vigente). */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('HELPER')")
    public AlertResponse get(@AuthenticationPrincipal AuthenticatedUser principal, @PathVariable Long id) {
        return alertService.getForHelper(principal.id(), id);
    }

    /** Auxiliador: confirma que recibió la alerta. */
    @PostMapping("/{id}/acknowledge")
    @PreAuthorize("hasRole('HELPER')")
    public AlertResponse acknowledge(@AuthenticationPrincipal AuthenticatedUser principal, @PathVariable Long id) {
        return alertService.acknowledge(principal.id(), id);
    }

    /** Usuario monitoreado: comparte su ubicación actual durante SU alerta. */
    @PostMapping("/{id}/location")
    @PreAuthorize("hasRole('MONITORED')")
    public ResponseEntity<Void> shareLocation(@AuthenticationPrincipal AuthenticatedUser principal,
                                              @PathVariable Long id,
                                              @Valid @RequestBody UpdateLocationRequest request) {
        alertService.shareLocation(principal.id(), id, request);
        return ResponseEntity.noContent().build();
    }
}
