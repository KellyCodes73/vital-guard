package com.vitalguard.trustedcontact.dto;

import com.vitalguard.trustedcontact.entity.LinkStatus;
import com.vitalguard.trustedcontact.entity.TrustedContactLink;
import java.time.Instant;

public record TrustedContactResponse(Long id, LinkStatus status, String inviteCode, Instant expiresAt,
                                     Instant createdAt, Instant acceptedAt,
                                     PersonSummary monitoredUser, PersonSummary helperUser) {

    /** Vista del usuario monitoreado: ve el código solo mientras la invitación está pendiente. */
    public static TrustedContactResponse forMonitored(TrustedContactLink l) {
        boolean pending = l.getStatus() == LinkStatus.PENDING;
        return new TrustedContactResponse(
                l.getId(), l.getStatus(),
                pending ? l.getInviteCode() : null,
                pending ? l.getExpiresAt() : null,
                l.getCreatedAt(), l.getAcceptedAt(),
                null, PersonSummary.from(l.getHelperUser()));
    }

    /** Vista del auxiliador: nunca ve el código y solo el nombre del usuario monitoreado. */
    public static TrustedContactResponse forHelper(TrustedContactLink l) {
        return new TrustedContactResponse(
                l.getId(), l.getStatus(), null, null,
                l.getCreatedAt(), l.getAcceptedAt(),
                PersonSummary.from(l.getMonitoredUser()), null);
    }
}
