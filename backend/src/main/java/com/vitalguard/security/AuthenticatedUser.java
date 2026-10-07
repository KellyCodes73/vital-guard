package com.vitalguard.security;

import com.vitalguard.user.entity.Role;

/** Usuario autenticado disponible en los controladores con @AuthenticationPrincipal. */
public record AuthenticatedUser(Long id, String email, Role role) {
}
