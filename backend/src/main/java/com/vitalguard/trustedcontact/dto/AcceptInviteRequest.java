package com.vitalguard.trustedcontact.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record AcceptInviteRequest(
        @NotBlank @Pattern(regexp = "^\\d{6}$", message = "debe tener 6 dígitos") String code) {
}
