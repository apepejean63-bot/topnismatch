package com.topnismatch.premium.controller;

import com.topnismatch.premium.dto.*;
import com.topnismatch.premium.service.PremiumService;
import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class PremiumController {

    private final PremiumService premiumService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @GetMapping("/subscription")
    public ResponseEntity<SuscripcionResponse> obtenerSuscripcion(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(premiumService.obtenerSuscripcion(usuarioId));
    }

    @PostMapping("/subscription/upgrade")
    public ResponseEntity<SuscripcionResponse> upgradePremium(
            @Valid @RequestBody UpgradeRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(premiumService.upgradePremium(usuarioId, request));
    }

    @PostMapping("/boost")
    public ResponseEntity<BoostResponse> activarBoost(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(premiumService.activarBoost(usuarioId));
    }

    @GetMapping("/notifications/config")
    public ResponseEntity<NotifConfigResponse> obtenerConfigNotif(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(premiumService.obtenerConfigNotif(usuarioId));
    }

    @PutMapping("/notifications/config")
    public ResponseEntity<NotifConfigResponse> actualizarConfigNotif(
            @RequestBody NotifConfigRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(premiumService.actualizarConfigNotif(usuarioId, request));
    }
}