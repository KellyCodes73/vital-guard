package com.vitalguard.notification.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Envío REAL con Firebase Cloud Messaging. Se activa con FCM_ENABLED=true. */
@Component
@ConditionalOnProperty(name = "app.fcm.enabled", havingValue = "true")
public class FcmPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);

    /** Canal de alta prioridad creado por la app (MainActivity.kt): suena como alarma y aparece como ventana emergente. */
    private static final String ALERT_CHANNEL_ID = "vital_guard_alerts";

    private final FirebaseMessaging messaging;

    public FcmPushSender(@Value("${app.fcm.service-account-path:}") String serviceAccountPath) throws IOException {
        if (serviceAccountPath == null || serviceAccountPath.isBlank()) {
            throw new IllegalStateException(
                    "FCM_ENABLED=true pero falta FCM_SERVICE_ACCOUNT_PATH (ruta al JSON de la cuenta de servicio).");
        }
        try (InputStream in = new FileInputStream(serviceAccountPath)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            FirebaseApp app = FirebaseApp.getApps().isEmpty()
                    ? FirebaseApp.initializeApp(options)
                    : FirebaseApp.getInstance();
            this.messaging = FirebaseMessaging.getInstance(app);
        }
        log.info("FCM habilitado: credenciales de Firebase cargadas correctamente.");
    }

    @Override
    public String channel() {
        return "FCM";
    }

    @Override
    public boolean send(String fcmToken, String title, String body, Map<String, String> data) {
        if (fcmToken == null || fcmToken.isBlank()) {
            log.warn("No se envió el push: el auxiliador no tiene token FCM registrado (¿abrió la app en su teléfono?).");
            return false;
        }
        try {
            Message.Builder builder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setChannelId(ALERT_CHANNEL_ID)
                                    .setPriority(AndroidNotification.Priority.MAX)
                                    .build())
                            .build());
            if (data != null) {
                builder.putAllData(data);
            }
            String messageId = messaging.send(builder.build());
            log.info("Push FCM enviado ({})", messageId);
            return true;
        } catch (FirebaseMessagingException e) {
            log.warn("Firebase rechazó el envío: {}", e.getMessage());
            return false;
        }
    }
}
