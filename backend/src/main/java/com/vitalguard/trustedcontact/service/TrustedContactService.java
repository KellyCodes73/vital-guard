package com.vitalguard.trustedcontact.service;

import com.vitalguard.common.ConflictException;
import com.vitalguard.common.NotFoundException;
import com.vitalguard.trustedcontact.dto.TrustedContactResponse;
import com.vitalguard.trustedcontact.entity.LinkStatus;
import com.vitalguard.trustedcontact.entity.TrustedContactLink;
import com.vitalguard.trustedcontact.repository.TrustedContactLinkRepository;
import com.vitalguard.user.entity.Role;
import com.vitalguard.user.repository.UserRepository;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TrustedContactService {

    private static final Duration INVITE_VALIDITY = Duration.ofHours(24);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final TrustedContactLinkRepository linkRepository;
    private final UserRepository userRepository;

    public TrustedContactService(TrustedContactLinkRepository linkRepository, UserRepository userRepository) {
        this.linkRepository = linkRepository;
        this.userRepository = userRepository;
    }

    /**
     * Crea una invitación. Reglas (MVP: una sola persona de confianza):
     * - si ya hay una vinculación ACTIVA -> 409
     * - si hay una invitación PENDIENTE vigente -> se devuelve la misma
     * - si la pendiente venció -> se descarta y se crea una nueva
     */
    @Transactional
    public TrustedContactResponse invite(Long monitoredUserId) {
        List<TrustedContactLink> current = linkRepository.findByMonitoredUserIdAndStatusIn(
                monitoredUserId, List.of(LinkStatus.PENDING, LinkStatus.ACTIVE));
        Instant now = Instant.now();

        for (TrustedContactLink link : current) {
            if (link.getStatus() == LinkStatus.ACTIVE) {
                throw new ConflictException(
                        "Ya tienes una persona de confianza vinculada. Revoca el acceso para invitar a otra.");
            }
        }
        for (TrustedContactLink link : current) {
            if (link.getExpiresAt().isAfter(now)) {
                return TrustedContactResponse.forMonitored(link);
            }
            link.setStatus(LinkStatus.REVOKED);
            link.setRevokedAt(now);
            linkRepository.save(link);
        }

        TrustedContactLink link = new TrustedContactLink();
        link.setMonitoredUser(userRepository.getReferenceById(monitoredUserId));
        link.setInviteCode(generateUniqueCode());
        link.setStatus(LinkStatus.PENDING);
        link.setCreatedAt(now);
        link.setExpiresAt(now.plus(INVITE_VALIDITY));
        return TrustedContactResponse.forMonitored(linkRepository.save(link));
    }

    @Transactional
    public TrustedContactResponse accept(Long helperUserId, String code) {
        TrustedContactLink link = linkRepository
                .findByInviteCodeAndStatus(code.trim(), LinkStatus.PENDING)
                .orElseThrow(() -> new NotFoundException("Código de invitación no válido"));
        Instant now = Instant.now();
        if (!link.getExpiresAt().isAfter(now)) {
            throw new IllegalArgumentException("La invitación expiró. Pide un código nuevo.");
        }
        link.setHelperUser(userRepository.getReferenceById(helperUserId));
        link.setStatus(LinkStatus.ACTIVE);
        link.setAcceptedAt(now);
        return TrustedContactResponse.forHelper(linkRepository.save(link));
    }

    /** Solo el usuario monitoreado puede revocar (o cancelar una invitación pendiente). */
    @Transactional
    public void revoke(Long monitoredUserId, Long linkId) {
        TrustedContactLink link = linkRepository.findByIdAndMonitoredUserId(linkId, monitoredUserId)
                .orElseThrow(() -> new NotFoundException("Vinculación no encontrada"));
        if (link.getStatus() != LinkStatus.REVOKED) {
            link.setStatus(LinkStatus.REVOKED);
            link.setRevokedAt(Instant.now());
            linkRepository.save(link);
        }
    }

    @Transactional(readOnly = true)
    public List<TrustedContactResponse> list(Long userId, Role role) {
        if (role == Role.HELPER) {
            return linkRepository.findByHelperUserIdAndStatus(userId, LinkStatus.ACTIVE).stream()
                    .map(TrustedContactResponse::forHelper)
                    .toList();
        }
        Instant now = Instant.now();
        return linkRepository.findByMonitoredUserIdAndStatusIn(
                        userId, List.of(LinkStatus.PENDING, LinkStatus.ACTIVE)).stream()
                .filter(l -> l.getStatus() == LinkStatus.ACTIVE || l.getExpiresAt().isAfter(now))
                .map(TrustedContactResponse::forMonitored)
                .toList();
    }

    private String generateUniqueCode() {
        for (int i = 0; i < 20; i++) {
            String code = String.format("%06d", RANDOM.nextInt(1_000_000));
            if (!linkRepository.existsByInviteCode(code)) {
                return code;
            }
        }
        throw new IllegalStateException("No se pudo generar un código de invitación único");
    }
}
