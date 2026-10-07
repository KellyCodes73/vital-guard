package com.vitalguard.trustedcontact.dto;

import com.vitalguard.user.entity.User;

/** Solo lo mínimo necesario de la otra persona: id y nombre (sin correo). */
public record PersonSummary(Long id, String name, String lastName) {
    public static PersonSummary from(User u) {
        return u == null ? null : new PersonSummary(u.getId(), u.getName(), u.getLastName());
    }
}
