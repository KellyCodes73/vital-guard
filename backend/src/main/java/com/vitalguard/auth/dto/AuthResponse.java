package com.vitalguard.auth.dto;

import com.vitalguard.user.dto.UserResponse;

public record AuthResponse(String token, UserResponse user) {
}
