package com.topnismatch.upload;

import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/upload")
@RequiredArgsConstructor
public class UploadController {

    private final JwtService jwtService;
    private final UploadService uploadService;

    @PostMapping("/foto")
    public ResponseEntity<Map<String, String>> subirFoto(
            @RequestParam("archivo") MultipartFile archivo,
            HttpServletRequest httpRequest) {
        try {
            String token = httpRequest.getHeader("Authorization").substring(7);
            Long usuarioId = jwtService.extractUsuarioId(token);

            String publicUrl = uploadService.subirFoto(archivo, usuarioId);

            return ResponseEntity.ok(Map.of("url", publicUrl));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}