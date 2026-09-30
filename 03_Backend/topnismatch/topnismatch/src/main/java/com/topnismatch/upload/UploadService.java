package com.topnismatch.upload;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UploadService {

    private static final long TAMANO_MAXIMO_BYTES = 5L * 1024 * 1024;

    private static final Map<String, String> TIPOS_PERMITIDOS = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp"
    );

    private final RestTemplate restTemplate;

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.service-key}")
    private String supabaseServiceKey;

    public String subirFoto(MultipartFile archivo, Long usuarioId) throws IOException {

        if (archivo == null || archivo.isEmpty()) {
            throw new RuntimeException("El archivo no puede estar vacio");
        }

        if (archivo.getSize() > TAMANO_MAXIMO_BYTES) {
            throw new RuntimeException("El archivo supera el tamano maximo permitido de 5 MB");
        }

        String contentType = archivo.getContentType();
        String extension = TIPOS_PERMITIDOS.get(contentType);
        if (extension == null) {
            throw new RuntimeException("Tipo de archivo no permitido. Solo se aceptan JPEG, PNG o WEBP");
        }

        String nombreArchivo = "user_" + usuarioId + "_" + System.currentTimeMillis() + "." + extension;
        String uploadUrl = supabaseUrl + "/storage/v1/object/fotos/" + nombreArchivo;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + supabaseServiceKey);
        headers.setContentType(MediaType.parseMediaType(contentType));
        headers.set("x-upsert", "true");

        HttpEntity<byte[]> entity = new HttpEntity<>(archivo.getBytes(), headers);
        restTemplate.exchange(uploadUrl, HttpMethod.PUT, entity, String.class);

        return supabaseUrl + "/storage/v1/object/public/fotos/" + nombreArchivo;
    }
}