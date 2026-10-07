package com.vitalguard.alert.service;

import com.vitalguard.alert.dto.AlertResponse;
import com.vitalguard.alert.dto.LocationResponse;
import com.vitalguard.alert.dto.UpdateLocationRequest;
import com.vitalguard.alert.entity.Alert;
import com.vitalguard.alert.entity.AlertStatus;
import com.vitalguard.alert.repository.AlertRepository;
import com.vitalguard.common.ConflictException;
import com.vitalguard.common.ForbiddenException;
import com.vitalguard.common.NotFoundException;
import com.vitalguard.event.entity.EventStatus;
import com.vitalguard.event.entity.RespiratoryEvent;
import com.vitalguard.location.entity.LocationSnapshot;
import com.vitalguard.location.repository.LocationSnapshotRepository;
import com.vitalguard.notification.service.NotificationService;
import com.vitalguard.trustedcontact.dto.PersonSummary;
import com.vitalguard.trustedcontact.entity.LinkStatus;
import com.vitalguard.trustedcontact.repository.TrustedContactLinkRepository;
import com.vitalguard.user.repository.UserRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AlertService {

    private final AlertRepository alertRepository;
    private final UserRepository userRepository;
    private final LocationSnapshotRepository locationRepository;
    private final TrustedContactLinkRepository linkRepository;
    private final NotificationService notificationService;
    private final long locationWindowMinutes;

    public AlertService(AlertRepository alertRepository,
                        UserRepository userRepository,
                        LocationSnapshotRepository locationRepository,
                        TrustedContactLinkRepository linkRepository,
                        NotificationService notificationService,
                        @Value("${app.alert.location-window-minutes:30}") long locationWindowMinutes) {
        this.alertRepository = alertRepository;
        this.userRepository = userRepository;
        this.locationRepository = locationRepository;
        this.linkRepository = linkRepository;
        this.notificationService = notificationService;
        this.locationWindowMinutes = locationWindowMinutes;
    }

    // ---------- creación (la usa EventService al escalar) ----------

    @Transactional
    public Alert createAlert(RespiratoryEvent event, Long helperUserId) {
        Instant now = Instant.now();
        Alert alert = new Alert();
        alert.setEvent(event);
        alert.setHelper(userRepository.getReferenceById(helperUserId));
        alert.setStatus(AlertStatus.ACTIVE);
        alert.setCreatedAt(now);
        alert.setLocationExpiresAt(now.plus(Duration.ofMinutes(locationWindowMinutes)));
        Alert saved = alertRepository.save(alert);
        notificationService.notifyAlertCreated(saved);
        return saved;
    }

    @Transactional(readOnly = true)
    public Long findAlertIdByEvent(Long eventId) {
        return alertRepository.findByEventId(eventId).map(Alert::getId).orElse(null);
    }

    // ---------- usuario monitoreado ----------

    /** Comparte (o actualiza) la ubicación SOLO mientras la ventana temporal de la alerta siga abierta. */
    @Transactional
    public void shareLocation(Long monitoredUserId, Long alertId, UpdateLocationRequest req) {
        Alert alert = alertRepository.findByIdAndEventUserId(alertId, monitoredUserId)
                .orElseThrow(() -> new NotFoundException("Alerta no encontrada"));
        Instant now = Instant.now();
        Instant expires = locationExpiry(alert);
        if (!now.isBefore(expires)) {
            throw new ConflictException("La ventana de ubicación temporal de esta alerta ya terminó");
        }
        LocationSnapshot snapshot = locationRepository.findByAlertId(alertId).orElseGet(() -> {
            LocationSnapshot s = new LocationSnapshot();
            s.setAlert(alert);
            return s;
        });
        snapshot.setLatitude(req.latitude());
        snapshot.setLongitude(req.longitude());
        snapshot.setAccuracyMeters(req.accuracyMeters());
        snapshot.setCapturedAt(now);
        snapshot.setExpiresAt(expires);
        locationRepository.save(snapshot);
    }

    // ---------- auxiliador ----------

    @Transactional(readOnly = true)
    public List<AlertResponse> listForHelper(Long helperId) {
        Set<Long> allowed = activeMonitoredIds(helperId);
        return alertRepository.findTop20ByHelperIdOrderByCreatedAtDesc(helperId).stream()
                .filter(a -> allowed.contains(a.getEvent().getUser().getId()))
                .map(a -> toResponse(a, false))
                .toList();
    }

    @Transactional(readOnly = true)
    public AlertResponse getForHelper(Long helperId, Long alertId) {
        return toResponse(findForHelper(helperId, alertId), true);
    }

    /** Confirmar recepción: cierra el evento. La ubicación sigue disponible hasta que termine su ventana. */
    @Transactional
    public AlertResponse acknowledge(Long helperId, Long alertId) {
        Alert alert = findForHelper(helperId, alertId);
        if (alert.getStatus() == AlertStatus.ACTIVE) {
            alert.setStatus(AlertStatus.ACKNOWLEDGED);
            alert.setAcknowledgedAt(Instant.now());
            alert.getEvent().setStatus(EventStatus.CERRADO);
            alertRepository.save(alert);
        }
        return toResponse(alert, true);
    }

    // ---------- utilidades ----------

    private Alert findForHelper(Long helperId, Long alertId) {
        Alert alert = alertRepository.findByIdAndHelperId(alertId, helperId)
                .orElseThrow(() -> new NotFoundException("Alerta no encontrada"));
        // Si el usuario revocó la vinculación, el auxiliador pierde el acceso (también a la ubicación).
        if (!activeMonitoredIds(helperId).contains(alert.getEvent().getUser().getId())) {
            throw new ForbiddenException("La vinculación fue revocada");
        }
        return alert;
    }

    private Set<Long> activeMonitoredIds(Long helperId) {
        return linkRepository.findByHelperUserIdAndStatus(helperId, LinkStatus.ACTIVE).stream()
                .map(l -> l.getMonitoredUser().getId())
                .collect(Collectors.toSet());
    }

    private Instant locationExpiry(Alert a) {
        return a.getLocationExpiresAt() != null
                ? a.getLocationExpiresAt()
                : a.getCreatedAt().plus(Duration.ofMinutes(locationWindowMinutes));
    }

    private AlertResponse toResponse(Alert a, boolean includeLocation) {
        RespiratoryEvent event = a.getEvent();
        Instant expires = locationExpiry(a);
        boolean windowOpen = Instant.now().isBefore(expires);
        Optional<LocationSnapshot> snapshot = locationRepository.findByAlertId(a.getId());
        boolean available = windowOpen && snapshot.isPresent();
        LocationResponse location = (includeLocation && available) ? LocationResponse.from(snapshot.get()) : null;
        return new AlertResponse(a.getId(), a.getStatus(), a.getCreatedAt(), a.getAcknowledgedAt(),
                event.getDetectedAt(), PersonSummary.from(event.getUser()),
                available, expires, location);
    }
}
