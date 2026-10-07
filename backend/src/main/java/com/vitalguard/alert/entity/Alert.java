package com.vitalguard.alert.entity;

import com.vitalguard.event.entity.RespiratoryEvent;
import com.vitalguard.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "alerts")
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false, unique = true)
    private RespiratoryEvent event;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "helper_user_id", nullable = false)
    private User helper;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AlertStatus status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "acknowledged_at")
    private Instant acknowledgedAt;

    @Column(name = "closed_at")
    private Instant closedAt;

    /** Fin de la ventana de ubicación temporal. Puede ser null en alertas antiguas (se calcula). */
    @Column(name = "location_expires_at")
    private Instant locationExpiresAt;

    public Long getId() { return id; }
    public RespiratoryEvent getEvent() { return event; }
    public void setEvent(RespiratoryEvent event) { this.event = event; }
    public User getHelper() { return helper; }
    public void setHelper(User helper) { this.helper = helper; }
    public AlertStatus getStatus() { return status; }
    public void setStatus(AlertStatus status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getAcknowledgedAt() { return acknowledgedAt; }
    public void setAcknowledgedAt(Instant acknowledgedAt) { this.acknowledgedAt = acknowledgedAt; }
    public Instant getClosedAt() { return closedAt; }
    public void setClosedAt(Instant closedAt) { this.closedAt = closedAt; }
    public Instant getLocationExpiresAt() { return locationExpiresAt; }
    public void setLocationExpiresAt(Instant locationExpiresAt) { this.locationExpiresAt = locationExpiresAt; }
}
