package com.vitalguard.user.controller;

import com.vitalguard.security.AuthenticatedUser;
import com.vitalguard.user.dto.FcmTokenRequest;
import com.vitalguard.user.dto.UpdateUserRequest;
import com.vitalguard.user.dto.UserResponse;
import com.vitalguard.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal AuthenticatedUser principal) {
        return userService.getMe(principal.id());
    }

    @PutMapping("/me")
    public UserResponse update(@AuthenticationPrincipal AuthenticatedUser principal,
                               @Valid @RequestBody UpdateUserRequest request) {
        return userService.updateMe(principal.id(), request);
    }

    @PutMapping("/me/fcm-token")
    public ResponseEntity<Void> updateFcmToken(@AuthenticationPrincipal AuthenticatedUser principal,
                                               @Valid @RequestBody FcmTokenRequest request) {
        userService.updateFcmToken(principal.id(), request.token());
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/me/fcm-token")
    public ResponseEntity<Void> clearFcmToken(@AuthenticationPrincipal AuthenticatedUser principal) {
        userService.clearFcmToken(principal.id());
        return ResponseEntity.noContent().build();
    }
}
