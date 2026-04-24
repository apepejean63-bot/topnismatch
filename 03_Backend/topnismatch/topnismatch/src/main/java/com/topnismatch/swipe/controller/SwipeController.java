package com.topnismatch.swipe.controller;

import com.topnismatch.security.JwtService;
import com.topnismatch.swipe.dto.*;
import com.topnismatch.swipe.service.SwipeService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class SwipeController {

    private final SwipeService swipeService;
    private final JwtService jwtService;

    private Long getUserIdFromRequest(HttpServletRequest request) {
        String token = request.getHeader("Authorization").substring(7);
        return jwtService.extractUsuarioId(token);
    }

    @GetMapping("/discover")
    public ResponseEntity<List<DiscoverResponse>> discover(
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(swipeService.discover(usuarioId));
    }

    @PostMapping("/swipe/like/{usuarioDestinoId}")
    public ResponseEntity<SwipeResponse> darLike(
            @PathVariable Long usuarioDestinoId,
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(swipeService.darLike(usuarioId, usuarioDestinoId));
    }

    @PostMapping("/swipe/dislike/{usuarioDestinoId}")
    public ResponseEntity<SwipeResponse> darDislike(
            @PathVariable Long usuarioDestinoId,
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(swipeService.darDislike(usuarioId, usuarioDestinoId));
    }

    @PostMapping("/swipe/superlike/{usuarioDestinoId}")
    public ResponseEntity<SwipeResponse> darSuperlike(
            @PathVariable Long usuarioDestinoId,
            HttpServletRequest request) {
        Long usuarioId = getUserIdFromRequest(request);
        return ResponseEntity.ok(swipeService.darSuperlike(usuarioId, usuarioDestinoId));
    }
}