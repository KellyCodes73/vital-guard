package com.vitalguard.trustedcontact.repository;

import com.vitalguard.trustedcontact.entity.LinkStatus;
import com.vitalguard.trustedcontact.entity.TrustedContactLink;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrustedContactLinkRepository extends JpaRepository<TrustedContactLink, Long> {
    Optional<TrustedContactLink> findByInviteCodeAndStatus(String inviteCode, LinkStatus status);
    List<TrustedContactLink> findByMonitoredUserIdAndStatusIn(Long monitoredUserId, Collection<LinkStatus> statuses);
    List<TrustedContactLink> findByHelperUserIdAndStatus(Long helperUserId, LinkStatus status);
    Optional<TrustedContactLink> findByIdAndMonitoredUserId(Long id, Long monitoredUserId);
    boolean existsByInviteCode(String inviteCode);
}
