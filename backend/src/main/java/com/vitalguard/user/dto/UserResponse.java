package com.vitalguard.user.dto;

import com.vitalguard.user.entity.Role;
import com.vitalguard.user.entity.User;

public record UserResponse(Long id, String name, String lastName, String email, Role role) {
    public static UserResponse from(User u) {
        return new UserResponse(u.getId(), u.getName(), u.getLastName(), u.getEmail(), u.getRole());
    }
}
