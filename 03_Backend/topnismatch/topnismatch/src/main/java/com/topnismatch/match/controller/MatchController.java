package com.topnismatch.match.controller;

import com.topnismatch.match.dto.*;
import com.topnismatch.match.service.MatchService;
import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @GetMapping("/matches")
    public ResponseEntity<List<MatchResponse>> obtenerMisMatches(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(matchService.obtenerMisMatches(usuarioId));
    }

    @GetMapping("/matches/{matchId}")
    public ResponseEntity<MatchResponse> obtenerMatchPorId(
            @PathVariable Long matchId,
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(matchService.obtenerMatchPorId(matchId, usuarioId));
    }

    @DeleteMapping("/matches/{matchId}")
    public ResponseEntity<Void> eliminarMatch(
            @PathVariable Long matchId,
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        matchService.eliminarMatch(matchId, usuarioId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/likes/me")
    public ResponseEntity<List<LikeResponse>> obtenerQuienMeDioLike(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(matchService.obtenerQuienMeDioLike(usuarioId));
    }
}