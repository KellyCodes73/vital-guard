package com.vitalguard.trustedcontact.controller;

import com.vitalguard.security.AuthenticatedUser;
import com.vitalguard.trustedcontact.dto.AcceptInviteRequest;
import com.vitalguard.trustedcontact.dto.TrustedContactResponse;
import com.vitalguard.trustedcontact.service.TrustedContactService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/trusted-contacts")
public class TrustedContactController {

    private final TrustedContactService service;

    public TrustedContactController(TrustedContactService service) {
        this.service = service;
    }

    @PostMapping("/invite")
    @PreAuthorize("hasRole('MONITORED')")
    public TrustedContactResponse invite(@AuthenticationPrincipal AuthenticatedUser principal) {
        return service.invite(principal.id());
    }

    @PostMapping("/accept")
    @PreAuthorize("hasRole('HELPER')")
    public TrustedContactResponse accept(@AuthenticationPrincipal AuthenticatedUser principal,
                                         @Valid @RequestBody AcceptInviteRequest request) {
        return service.accept(principal.id(), request.code());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('MONITORED')")
    public ResponseEntity<Void> revoke(@AuthenticationPrincipal AuthenticatedUser principal,
                                       @PathVariable Long id) {
        service.revoke(principal.id(), id);
        return ResponseEntity.noContent().build();
    }

    /** Monitoreado: su invitación/vinculación vigente. Auxiliador: las personas que lo autorizaron. */
    @GetMapping
    public List<TrustedContactResponse> list(@AuthenticationPrincipal AuthenticatedUser principal) {
        return service.list(principal.id(), principal.role());
    }
}
