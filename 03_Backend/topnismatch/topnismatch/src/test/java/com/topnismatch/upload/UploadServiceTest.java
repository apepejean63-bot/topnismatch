package com.topnismatch.upload;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class UploadServiceTest {

    private RestTemplate restTemplateMock;
    private UploadService uploadService;

    @BeforeEach
    void configurar() {
        restTemplateMock = mock(RestTemplate.class);
        uploadService = new UploadService(restTemplateMock);
        ReflectionTestUtils.setField(uploadService, "supabaseUrl", "https://fake-supabase.test");
        ReflectionTestUtils.setField(uploadService, "supabaseServiceKey", "fake-service-key-123");
    }

    private void simularSupabaseExitoso() {
        when(restTemplateMock.exchange(
                anyString(), eq(HttpMethod.PUT), any(HttpEntity.class), eq(String.class)
        )).thenReturn(ResponseEntity.ok("OK"));
    }

    @Test
    void subirFotoJpegValidaDeberiaFuncionar() throws Exception {
        simularSupabaseExitoso();

        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "foto.jpg", "image/jpeg", "contenido-falso-jpeg".getBytes());

        String url = uploadService.subirFoto(archivo, 42L);

        assertTrue(url.endsWith(".jpg"), "La URL deberia terminar en .jpg para un archivo JPEG");
        assertTrue(url.contains("user_42_"));
        verify(restTemplateMock, times(1)).exchange(
                anyString(), eq(HttpMethod.PUT), any(HttpEntity.class), eq(String.class));
    }

    @Test
    void subirFotoPngValidaDeberiaConservarExtensionPng() throws Exception {
        simularSupabaseExitoso();

        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "foto.png", "image/png", "contenido-falso-png".getBytes());

        String url = uploadService.subirFoto(archivo, 42L);

        assertTrue(url.endsWith(".png"), "La URL deberia terminar en .png para un archivo PNG");
    }

    @Test
    void subirFotoWebpValidaDeberiaConservarExtensionWebp() throws Exception {
        simularSupabaseExitoso();

        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "foto.webp", "image/webp", "contenido-falso-webp".getBytes());

        String url = uploadService.subirFoto(archivo, 42L);

        assertTrue(url.endsWith(".webp"), "La URL deberia terminar en .webp para un archivo WEBP");
    }

    @Test
    void subirFotoConTipoNoPermitidoDeberiaSerRechazada() {
        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "documento.pdf", "application/pdf", "contenido-falso-pdf".getBytes());

        RuntimeException excepcion = assertThrows(RuntimeException.class, () -> {
            uploadService.subirFoto(archivo, 42L);
        });
        assertEquals("Tipo de archivo no permitido. Solo se aceptan JPEG, PNG o WEBP", excepcion.getMessage());

        verify(restTemplateMock, never()).exchange(
                anyString(), any(HttpMethod.class), any(HttpEntity.class), eq(String.class));
    }

    @Test
    void subirFotoVaciaDeberiaSerRechazada() {
        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "vacio.jpg", "image/jpeg", new byte[0]);

        RuntimeException excepcion = assertThrows(RuntimeException.class, () -> {
            uploadService.subirFoto(archivo, 42L);
        });
        assertEquals("El archivo no puede estar vacio", excepcion.getMessage());
    }

    @Test
    void subirFotoDemasiadoGrandeDeberiaSerRechazada() {
        byte[] contenidoGrande = new byte[6 * 1024 * 1024];
        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "grande.jpg", "image/jpeg", contenidoGrande);

        RuntimeException excepcion = assertThrows(RuntimeException.class, () -> {
            uploadService.subirFoto(archivo, 42L);
        });
        assertEquals("El archivo supera el tamano maximo permitido de 5 MB", excepcion.getMessage());
    }

    @Test
    void subirFotoConFalloDeSupabaseDeberiaPropagarError() {
        when(restTemplateMock.exchange(
                anyString(), eq(HttpMethod.PUT), any(HttpEntity.class), eq(String.class)
        )).thenThrow(new RestClientException("Supabase no responde"));

        MockMultipartFile archivo = new MockMultipartFile(
                "archivo", "foto.jpg", "image/jpeg", "contenido-falso-jpeg".getBytes());

        assertThrows(RestClientException.class, () -> {
            uploadService.subirFoto(archivo, 42L);
        });
    }
}