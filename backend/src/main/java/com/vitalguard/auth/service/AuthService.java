package com.vitalguard.auth.service;

import com.vitalguard.auth.dto.AuthResponse;
import com.vitalguard.auth.dto.LoginRequest;
import com.vitalguard.auth.dto.RegisterRequest;
import com.vitalguard.common.ConflictException;
import com.vitalguard.common.UnauthorizedException;
import com.vitalguard.security.JwtService;
import com.vitalguard.user.dto.UserResponse;
import com.vitalguard.user.entity.User;
import com.vitalguard.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (!req.password().equals(req.confirmPassword())) {
            throw new IllegalArgumentException("Las contraseñas no coinciden");
        }
        String email = normalize(req.email());
        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("Ya existe una cuenta con ese correo");
        }
        User user = new User();
        user.setName(req.name().trim());
        user.setLastName(req.lastName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user.setRole(req.role());
        user = userRepository.save(user);
        return new AuthResponse(jwtService.generateToken(user), UserResponse.from(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByEmail(normalize(req.email()))
                .orElseThrow(() -> new UnauthorizedException("Credenciales inválidas"));
        if (!passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            throw new UnauthorizedException("Credenciales inválidas");
        }
        return new AuthResponse(jwtService.generateToken(user), UserResponse.from(user));
    }

    private String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
