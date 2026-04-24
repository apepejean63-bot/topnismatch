package com.topnismatch.profile.controller;

import com.topnismatch.profile.dto.*;
import com.topnismatch.profile.service.ProfileService;
import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @PostMapping
    public ResponseEntity<ProfileResponse> crearPerfil(
            @Valid @RequestBody ProfileRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(profileService.crearPerfil(usuarioId, request));
    }

    @PutMapping
    public ResponseEntity<ProfileResponse> editarPerfil(
            @Valid @RequestBody ProfileRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(profileService.editarPerfil(usuarioId, request));
    }

    @GetMapping("/me")
    public ResponseEntity<ProfileResponse> obtenerMiPerfil(
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(profileService.obtenerMiPerfil(usuarioId));
    }

    @GetMapping("/{perfilId}")
    public ResponseEntity<ProfileResponse> obtenerPerfilPorId(
            @PathVariable Long perfilId) {
        return ResponseEntity.ok(profileService.obtenerPerfilPorId(perfilId));
    }

    @PostMapping("/photos")
    public ResponseEntity<FotoResponse> agregarFoto(
            @Valid @RequestBody FotoRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(profileService.agregarFoto(usuarioId, request));
    }

    @DeleteMapping("/photos/{orden}")
    public ResponseEntity<Void> eliminarFoto(
            @PathVariable Integer orden,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        profileService.eliminarFoto(usuarioId, orden);
        return ResponseEntity.noContent().build();
    }
}