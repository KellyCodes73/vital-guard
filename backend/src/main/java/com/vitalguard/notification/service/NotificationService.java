package com.vitalguard.notification.service;

import com.vitalguard.alert.entity.Alert;
import com.vitalguard.notification.entity.Notification;
import com.vitalguard.notification.entity.NotificationStatus;
import com.vitalguard.notification.entity.NotificationType;
import com.vitalguard.notification.repository.NotificationRepository;
import com.vitalguard.user.entity.User;
import java.time.Instant;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final PushSender pushSender;

    public NotificationService(NotificationRepository notificationRepository, PushSender pushSender) {
        this.notificationRepository = notificationRepository;
        this.pushSender = pushSender;
    }

    /** Avisa al auxiliador de una alerta nueva. Un fallo del envío nunca debe impedir crear la alerta. */
    @Transactional
    public void notifyAlertCreated(Alert alert) {
        User helper = alert.getHelper();
        String monitoredName = alert.getEvent().getUser().getName();
        String title = "Alerta de Vital Guard";
        String body = "Vital Guard detectó un posible patrón respiratorio inusual en " + monitoredName + ".";

        NotificationStatus status;
        try {
            boolean sent = pushSender.send(helper.getFcmToken(), title, body,
                    Map.of("type", "ALERT_CREATED", "alertId", String.valueOf(alert.getId())));
            status = sent ? NotificationStatus.SENT : NotificationStatus.FAILED;
        } catch (Exception ex) {
            log.warn("No se pudo enviar la notificación de la alerta {}", alert.getId(), ex);
            status = NotificationStatus.FAILED;
        }

        Notification n = new Notification();
        n.setUser(helper);
        n.setAlert(alert);
        n.setType(NotificationType.ALERT_CREATED);
        n.setChannel(pushSender.channel());
        n.setStatus(status);
        n.setTitle(title);
        n.setBody(body);
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }
}
