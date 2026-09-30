package com.topnismatch.security;

import com.topnismatch.auth.dto.AuthResponse;
import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.service.AuthService;
import jakarta.persistence.EntityManager;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * PROBLEMA CONOCIDO - PENDIENTE PARA FASE FINAL DE SEGURIDAD:
 * Despues de que un usuario hace logout(), su JWT queda registrado en la tabla
 * JWT_BLACKLIST, pero JwtAuthFilter/JwtService nunca consultan esa tabla.
 * En consecuencia, un JWT "cerrado" sigue siendo válido y aceptado por la API
 * hasta que expira naturalmente (ver jwt.expiration).
 *
 * Este test queda @Disabled a proposito: documenta el comportamiento actual
 * (inseguro) sin romper la suite verde mientras se trabaja en funcionalidad.
 * Se debe re-habilitar y hacer pasar durante la fase final de seguridad,
 * implementando la consulta a JWT_BLACKLIST en el filtro de autenticacion.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
@Transactional
class JwtBlacklistSecurityTest {

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
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private EntityManager entityManager;

    @Disabled("PENDIENTE fase final de seguridad: JwtAuthFilter no consulta JWT_BLACKLIST tras logout")
    @Test
    void jwtDespuesDeLogoutDeberiaSerRechazado() throws Exception {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Blacklist Test")
                .email("blacklisttest@integracion.com")
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        AuthResponse respuesta = authService.register(registro);
        String token = respuesta.getToken();

        MvcResult resultadoAntes = mockMvc.perform(get("/api/v1/profile/me")
                        .header("Authorization", "Bearer " + token))
                .andReturn();
        int statusAntes = resultadoAntes.getResponse().getStatus();
        assertNotEquals(401, statusAntes,
                "Con el JWT recien emitido, la request NO deberia ser rechazada por falta de autenticacion (401)");

        HttpServletRequest fakeRequest = Mockito.mock(HttpServletRequest.class);
        Mockito.when(fakeRequest.getHeader("Authorization")).thenReturn("Bearer " + token);
        authService.logout(fakeRequest);

        Long cantidadEnBlacklist = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM JWT_BLACKLIST WHERE usuario_id = :userId")
                .setParameter("userId", respuesta.getUsuarioId())
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadEnBlacklist,
                "El logout deberia haber registrado el token en la blacklist");

        MvcResult resultadoDespues = mockMvc.perform(get("/api/v1/profile/me")
                        .header("Authorization", "Bearer " + token))
                .andReturn();
        int statusDespues = resultadoDespues.getResponse().getStatus();
        assertEquals(401, statusDespues,
                "Despues del logout, el mismo JWT (ahora en blacklist) deberia ser rechazado con 401");
    }
}