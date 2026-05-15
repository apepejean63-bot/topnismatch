package com.topnismatch.upload;

import com.topnismatch.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/upload")
@RequiredArgsConstructor
public class UploadController {

    private final JwtService jwtService;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.service-key}")
    private String supabaseServiceKey;

    @PostMapping("/foto")
    public ResponseEntity<Map<String, String>> subirFoto(
            @RequestParam("archivo") MultipartFile archivo,
            HttpServletRequest httpRequest) {
        try {
            String token = httpRequest.getHeader("Authorization").substring(7);
            Long usuarioId = jwtService.extractUsuarioId(token);

            String nombreArchivo = "user_" + usuarioId + "_" + System.currentTimeMillis() + ".jpg";
            String uploadUrl = supabaseUrl + "/storage/v1/object/fotos/" + nombreArchivo;

            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + supabaseServiceKey);
            headers.setContentType(MediaType.IMAGE_JPEG);
            headers.set("x-upsert", "true");

            HttpEntity<byte[]> entity = new HttpEntity<>(archivo.getBytes(), headers);
            restTemplate.exchange(uploadUrl, HttpMethod.PUT, entity, String.class);

            String publicUrl = supabaseUrl + "/storage/v1/object/public/fotos/" + nombreArchivo;
            return ResponseEntity.ok(Map.of("url", publicUrl));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}