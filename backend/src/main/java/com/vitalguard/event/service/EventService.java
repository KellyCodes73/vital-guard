package com.vitalguard.event.service;

import com.vitalguard.alert.entity.Alert;
import com.vitalguard.alert.service.AlertService;
import com.vitalguard.common.ConflictException;
import com.vitalguard.common.NotFoundException;
import com.vitalguard.event.dto.CreateEventRequest;
import com.vitalguard.event.dto.EventResponse;
import com.vitalguard.event.entity.EventStatus;
import com.vitalguard.event.entity.RespiratoryEvent;
import com.vitalguard.event.repository.RespiratoryEventRepository;
import com.vitalguard.monitoring.entity.MonitoringSession;
import com.vitalguard.monitoring.entity.SessionStatus;
import com.vitalguard.monitoring.repository.MonitoringSessionRepository;
import com.vitalguard.trustedcontact.entity.LinkStatus;
import com.vitalguard.trustedcontact.entity.TrustedContactLink;
import com.vitalguard.trustedcontact.repository.TrustedContactLinkRepository;
import com.vitalguard.user.repository.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EventService {

    private final RespiratoryEventRepository eventRepository;
    private final MonitoringSessionRepository sessionRepository;
    private final UserRepository userRepository;
    private final TrustedContactLinkRepository linkRepository;
    private final AlertService alertService;

    public EventService(RespiratoryEventRepository eventRepository,
                        MonitoringSessionRepository sessionRepository,
                        UserRepository userRepository,
                        TrustedContactLinkRepository linkRepository,
                        AlertService alertService) {
        this.eventRepository = eventRepository;
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
        this.linkRepository = linkRepository;
        this.alertService = alertService;
    }

    /** Registra un posible patrón respiratorio inusual (ya verificado por la app) dentro de una sesión activa. */
    @Transactional
    public EventResponse create(Long userId, CreateEventRequest req) {
        MonitoringSession session = sessionRepository.findByIdAndUserId(req.sessionId(), userId)
                .orElseThrow(() -> new NotFoundException("Sesión de monitoreo no encontrada"));
        if (session.getStatus() != SessionStatus.ACTIVE) {
            throw new ConflictException("El monitoreo ya no está activo");
        }
        RespiratoryEvent event = new RespiratoryEvent();
        event.setSession(session);
        event.setUser(userRepository.getReferenceById(userId));
        event.setDetectedAt(Instant.now());
        event.setConfidence(req.confidence());
        event.setSource(req.source());
        event.setStatus(EventStatus.DETECTED);
        return EventResponse.from(eventRepository.save(event));
    }

    @Transactional(readOnly = true)
    public List<EventResponse> list(Long userId) {
        return eventRepository.findTop100ByUserIdOrderByDetectedAtDesc(userId).stream()
                .map(EventResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public EventResponse get(Long userId, Long eventId) {
        return EventResponse.from(findOwned(userId, eventId));
    }

    /** "ESTOY BIEN": solo es posible mientras el evento sigue pendiente. */
    @Transactional
    public EventResponse resolve(Long userId, Long eventId) {
        RespiratoryEvent event = findOwned(userId, eventId);
        if (event.getStatus() == EventStatus.ATENDIDO_POR_USUARIO) {
            return EventResponse.from(event);
        }
        if (event.getStatus() != EventStatus.DETECTED) {
            throw new ConflictException("Este evento ya no puede marcarse como atendido");
        }
        event.setStatus(EventStatus.ATENDIDO_POR_USUARIO);
        event.setResolvedAt(Instant.now());
        return EventResponse.from(eventRepository.save(event));
    }

    /**
     * El usuario no respondió a tiempo: se crea la alerta para su persona de confianza.
     * Si no tiene una vinculación activa, el evento queda como SIN_AUXILIADOR.
     * La respuesta incluye alertId para que la app comparta la ubicación temporal.
     */
    @Transactional
    public EventResponse escalate(Long userId, Long eventId) {
        RespiratoryEvent event = findOwned(userId, eventId);
        if (event.getStatus() == EventStatus.NOTIFICADO_A_AUXILIADOR) {
            return EventResponse.from(event, alertService.findAlertIdByEvent(event.getId()));
        }
        if (event.getStatus() == EventStatus.SIN_AUXILIADOR) {
            return EventResponse.from(event);
        }
        if (event.getStatus() != EventStatus.DETECTED) {
            throw new ConflictException("Este evento ya fue atendido");
        }
        Optional<TrustedContactLink> link = linkRepository
                .findByMonitoredUserIdAndStatusIn(userId, List.of(LinkStatus.ACTIVE))
                .stream().findFirst();

        event.setEscalatedAt(Instant.now());
        Long alertId = null;
        if (link.isEmpty()) {
            event.setStatus(EventStatus.SIN_AUXILIADOR);
        } else {
            Alert alert = alertService.createAlert(event, link.get().getHelperUser().getId());
            alertId = alert.getId();
            event.setStatus(EventStatus.NOTIFICADO_A_AUXILIADOR);
        }
        return EventResponse.from(eventRepository.save(event), alertId);
    }

    private RespiratoryEvent findOwned(Long userId, Long eventId) {
        return eventRepository.findByIdAndUserId(eventId, userId)
                .orElseThrow(() -> new NotFoundException("Evento no encontrado"));
    }
}
