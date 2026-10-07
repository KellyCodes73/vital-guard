package com.vitalguard.monitoring.entity;

import com.vitalguard.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.LocalTime;

@Entity
@Table(name = "monitoring_configurations")
public class MonitoringConfiguration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "scheduled_enabled", nullable = false)
    private boolean scheduledEnabled;

    @Column(name = "alert_timeout_seconds", nullable = false)
    private int alertTimeoutSeconds;

    public Long getId() { return id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public LocalTime getStartTime() { return startTime; }
    public void setStartTime(LocalTime startTime) { this.startTime = startTime; }
    public LocalTime getEndTime() { return endTime; }
    public void setEndTime(LocalTime endTime) { this.endTime = endTime; }
    public boolean isScheduledEnabled() { return scheduledEnabled; }
    public void setScheduledEnabled(boolean scheduledEnabled) { this.scheduledEnabled = scheduledEnabled; }
    public int getAlertTimeoutSeconds() { return alertTimeoutSeconds; }
    public void setAlertTimeoutSeconds(int alertTimeoutSeconds) { this.alertTimeoutSeconds = alertTimeoutSeconds; }
}
