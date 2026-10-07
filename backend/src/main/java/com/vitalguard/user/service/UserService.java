package com.vitalguard.user.service;

import com.vitalguard.common.NotFoundException;
import com.vitalguard.user.dto.UpdateUserRequest;
import com.vitalguard.user.dto.UserResponse;
import com.vitalguard.user.entity.User;
import com.vitalguard.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
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

    private User find(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuario no encontrado"));
    }
}
