package com.topnismatch.admin.controller;

import com.topnismatch.admin.dto.*;
import com.topnismatch.admin.service.AdminService;
import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @GetMapping("/dashboard")
    public ResponseEntity<DashboardResponse> obtenerDashboard() {
        return ResponseEntity.ok(adminService.obtenerDashboard());
    }

    @GetMapping("/users")
    public ResponseEntity<List<AdminUserResponse>> listarUsuarios() {
        return ResponseEntity.ok(adminService.listarUsuarios());
    }

    @PutMapping("/users/{usuarioId}/status")
    public ResponseEntity<AdminUserResponse> cambiarEstadoUsuario(
            @PathVariable Long usuarioId,
            @RequestParam Boolean activo) {
        return ResponseEntity.ok(adminService.cambiarEstadoUsuario(usuarioId, activo));
    }

    @GetMapping("/reports")
    public ResponseEntity<List<AdminReportResponse>> listarReportes(
            @RequestParam(required = false) String estado) {
        return ResponseEntity.ok(adminService.listarReportes(estado));
    }

    @PutMapping("/reports/{reporteId}")
    public ResponseEntity<AdminReportResponse> resolverReporte(
            @PathVariable Long reporteId,
            @Valid @RequestBody ResolveReportRequest request,
            HttpServletRequest httpRequest) {
        Long adminId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(adminService.resolverReporte(reporteId, adminId, request));
    }
}