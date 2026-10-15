package com.vitalguard.user.service;

import com.vitalguard.common.NotFoundException;
import com.vitalguard.notification.service.NotificationService;
import com.vitalguard.user.dto.TestPushResponse;
import com.vitalguard.user.dto.UpdateUserRequest;
import com.vitalguard.user.dto.UserResponse;
import com.vitalguard.user.entity.User;
import com.vitalguard.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public UserService(UserRepository userRepository, NotificationService notificationService) {
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public UserResponse getMe(Long userId) {
        return UserResponse.from(find(userId));
    }

    @Transactional
    public UserResponse updateMe(Long userId, UpdateUserRequest req) {
        User user = find(userId);
        user.setName(req.name().trim());
        user.setLastName(req.lastName().trim());
        return UserResponse.from(userRepository.save(user));
    }

    /**
     * Registra el token FCM del teléfono. Un mismo teléfono solo puede pertenecer a una cuenta:
     * se lo quitamos a las demás para que una alerta nunca llegue a otra persona.
     */
    @Transactional
    public void updateFcmToken(Long userId, String token) {
        User user = find(userId);
        for (User other : userRepository.findByFcmToken(token)) {
            if (!other.getId().equals(userId)) {
                other.setFcmToken(null);
                userRepository.save(other);
            }
        }
        user.setFcmToken(token);
        userRepository.save(user);
    }

    /** Se usa al cerrar sesión: el teléfono deja de recibir las alertas de esta cuenta. */
    @Transactional
    public void clearFcmToken(Long userId) {
        User user = find(userId);
        user.setFcmToken(null);
        userRepository.save(user);
    }

    /** Envía una notificación de prueba al teléfono de esta cuenta (para comprobar sonido y ventana emergente). */
    @Transactional(readOnly = true)
    public TestPushResponse testPush(Long userId) {
        User user = find(userId);
        String channel = notificationService.channel();
        String token = user.getFcmToken();

        if ("LOG".equals(channel)) {
            return new TestPushResponse(false, channel,
                    "Las notificaciones están en modo simulado en el servidor (FCM desactivado).");
        }
        if (token == null || token.isBlank()) {
            return new TestPushResponse(false, channel,
                    "Este teléfono aún no tiene el aviso registrado. Cierra sesión, vuelve a entrar y acepta el permiso de notificaciones.");
        }
        boolean sent = notificationService.sendTest(token);
        return new TestPushResponse(sent, channel, sent
                ? "Notificación de prueba enviada. Bloquea la pantalla: debería llegar en unos segundos."
                : "Firebase rechazó el envío. Revisa los logs del servidor.");
    }

    private User find(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));
    }
}
