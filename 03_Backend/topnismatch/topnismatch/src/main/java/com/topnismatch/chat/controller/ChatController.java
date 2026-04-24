package com.topnismatch.chat.controller;

import com.topnismatch.chat.dto.*;
import com.topnismatch.chat.service.ChatService;
import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @PostMapping("/messages/{matchId}")
    public ResponseEntity<MensajeResponse> enviarMensaje(
            @PathVariable Long matchId,
            @Valid @RequestBody MensajeRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(chatService.enviarMensaje(matchId, usuarioId, request));
    }

    @GetMapping("/messages/{matchId}")
    public ResponseEntity<List<MensajeResponse>> obtenerHistorial(
            @PathVariable Long matchId,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        return ResponseEntity.ok(chatService.obtenerHistorial(matchId, usuarioId));
    }

    @PutMapping("/messages/{matchId}/read")
    public ResponseEntity<Void> marcarComoLeido(
            @PathVariable Long matchId,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        chatService.marcarComoLeido(matchId, usuarioId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/block/{usuarioBloqueadoId}")
    public ResponseEntity<Void> bloquearUsuario(
            @PathVariable Long usuarioBloqueadoId,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        chatService.bloquearUsuario(usuarioId, usuarioBloqueadoId);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/report/{usuarioDenunciadoId}")
    public ResponseEntity<Void> reportarUsuario(
            @PathVariable Long usuarioDenunciadoId,
            @Valid @RequestBody BlockReportRequest request,
            HttpServletRequest httpRequest) {
        Long usuarioId = getUserIdFromRequest(httpRequest);
        chatService.reportarUsuario(usuarioId, usuarioDenunciadoId, request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}