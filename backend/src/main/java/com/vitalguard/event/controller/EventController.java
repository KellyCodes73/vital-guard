package com.vitalguard.event.controller;

import com.vitalguard.event.dto.CreateEventRequest;
import com.vitalguard.event.dto.EventResponse;
import com.vitalguard.event.service.EventService;
import com.vitalguard.security.AuthenticatedUser;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Eventos del propio usuario monitoreado. */
@RestController
@RequestMapping("/api/events")
@PreAuthorize("hasRole('MONITORED')")
public class EventController {

    private final EventService eventService;

    public EventController(EventService eventService) {
        this.eventService = eventService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EventResponse create(@AuthenticationPrincipal AuthenticatedUser principal,
                                @Valid @RequestBody CreateEventRequest request) {
        return eventService.create(principal.id(), request);
    }

    @GetMapping
    public List<EventResponse> list(@AuthenticationPrincipal AuthenticatedUser principal) {
        return eventService.list(principal.id());
    }

    @GetMapping("/{id}")
    public EventResponse get(@AuthenticationPrincipal AuthenticatedUser principal, @PathVariable Long id) {
        return eventService.get(principal.id(), id);
    }

    @PostMapping("/{id}/resolve")
    public EventResponse resolve(@AuthenticationPrincipal AuthenticatedUser principal, @PathVariable Long id) {
        return eventService.resolve(principal.id(), id);
    }

    @PostMapping("/{id}/escalate")
    public EventResponse escalate(@AuthenticationPrincipal AuthenticatedUser principal, @PathVariable Long id) {
        return eventService.escalate(principal.id(), id);
    }
}
