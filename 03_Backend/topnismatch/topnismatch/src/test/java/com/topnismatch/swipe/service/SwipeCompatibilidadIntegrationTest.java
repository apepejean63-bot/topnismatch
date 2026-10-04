package com.topnismatch.swipe.service;

import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.service.AuthService;
import com.topnismatch.profile.dto.ProfileRequest;
import com.topnismatch.profile.service.ProfileService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@Testcontainers
@Transactional
class SwipeCompatibilidadIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17")
            .withInitScript("schema.sql");

    @DynamicPropertySource
    static void configurarPropiedades(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private SwipeService swipeService;

    @Autowired
    private AuthService authService;

    @Autowired
    private ProfileService profileService;

    @Autowired
    private EntityManager entityManager;

    private Long crearUsuarioConPerfil(String email, String intereses) {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Compat Test")
                .email(email)
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        Long usuarioId = authService.register(registro).getUsuarioId();

        ProfileRequest perfil = ProfileRequest.builder()
                .bio("Perfil de prueba")
                .intereses(intereses)
                .build();
        profileService.crearPerfil(usuarioId, perfil);
        return usuarioId;
    }

    private double compatibilidadDelMatch(Long a, Long b) {
        Number valor = (Number) entityManager.createNativeQuery(
                        "SELECT compatibilidad FROM MATCH_TOPNIS WHERE usuario1_id = :u1 AND usuario2_id = :u2")
                .setParameter("u1", Math.min(a, b))
                .setParameter("u2", Math.max(a, b))
                .getSingleResult();
        return valor.doubleValue();
    }

    @Test
    void matchConInteresesEnFormatosDistintosTiene100DeCompatibilidad() {
        // U+1F3B5 (nota musical) con escapes para evitar problemas de codificacion
        Long a = crearUsuarioConPerfil("compata@integracion.com", "\uD83C\uDFB5 M\u00FAsica, F\u00FAtbol");
        Long b = crearUsuarioConPerfil("compatb@integracion.com", "musica,futbol");

        swipeService.darLike(a, b);
        swipeService.darLike(b, a);

        assertEquals(100.0, compatibilidadDelMatch(a, b), 0.0001);
    }

    @Test
    void matchSinInteresesTieneCompatibilidadNeutraDe50() {
        Long a = crearUsuarioConPerfil("compatc@integracion.com", "");
        Long b = crearUsuarioConPerfil("compatd@integracion.com", "");

        swipeService.darLike(a, b);
        swipeService.darLike(b, a);

        assertEquals(50.0, compatibilidadDelMatch(a, b), 0.0001);
    }
}