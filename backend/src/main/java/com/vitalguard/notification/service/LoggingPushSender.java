package com.vitalguard.notification.service;

import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Envío SIMULADO: solo escribe en el log. Se usa mientras app.fcm.enabled no sea true. */
@Component
@ConditionalOnProperty(name = "app.fcm.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingPushSender.class);

    @Override
    public String channel() {
        return "LOG";
    }

    @Override
    public boolean send(String fcmToken, String title, String body, Map<String, String> data) {
        log.info("PUSH (simulado) -> {} | {} | {} | data={}",
                fcmToken == null ? "sin token FCM" : "token FCM registrado", title, body, data);
        return true;
    }
}
