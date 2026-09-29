package com.topnismatch.auth.service;

import com.topnismatch.auth.dto.AuthResponse;
import com.topnismatch.auth.dto.LoginRequest;
import com.topnismatch.auth.dto.RegisterRequest;
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

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@Transactional
class AuthServiceIntegrationTest {

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
    private AuthService authService;

    @Autowired
    private EntityManager entityManager;

    @Test
    void registerDeberiaCrearUsuarioConSuscripcionYPreferencias() {
        RegisterRequest request = RegisterRequest.builder()
                .nombre("Auth Test")
                .email("authtest@integracion.com")
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();

        AuthResponse respuesta = authService.register(request);

        assertNotNull(respuesta.getToken());
        assertNotNull(respuesta.getUsuarioId());
        assertEquals("USER", respuesta.getRol());
        assertEquals("GRATUITO", respuesta.getPlan());
        assertEquals("authtest@integracion.com", respuesta.getEmail());

        Long cantidadSuscripciones = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM SUSCRIPCION WHERE usuario_id = :userId AND plan = 'GRATUITO'")
                .setParameter("userId", respuesta.getUsuarioId())
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadSuscripciones, "Deberia crearse automaticamente una suscripcion GRATUITO");

        Long cantidadPreferencias = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM NOTIF_PREFERENCIAS WHERE usuario_id = :userId")
                .setParameter("userId", respuesta.getUsuarioId())
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadPreferencias, "Deberia crearse automaticamente una fila de preferencias de notificacion");
    }
    @Test
    void registerDeberiaRechazarEmailDuplicado() {
        RegisterRequest request = RegisterRequest.builder()
                .nombre("Duplicado Test")
                .email("duplicado@integracion.com")
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("FEMENINO")
                .build();

        authService.register(request);

        RegisterRequest requestDuplicado = RegisterRequest.builder()
                .nombre("Otro Nombre")
                .email("duplicado@integracion.com")
                .password("otraPassword123")
                .fechaNacimiento("1998-03-10")
                .genero("MASCULINO")
                .build();

        assertThrows(RuntimeException.class, () -> {
            authService.register(requestDuplicado);
        }, "No deberia permitirse registrar dos usuarios con el mismo email");

        Long cantidadUsuarios = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM USUARIO WHERE email = :email")
                .setParameter("email", "duplicado@integracion.com")
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadUsuarios, "Deberia seguir existiendo solamente 1 usuario con ese email");
    }
    @Test
    void loginDeberiaAceptarCredencialesCorrectas() {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Login Test")
                .email("logintest@integracion.com")
                .password("passwordCorrecto123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        AuthResponse respuestaRegistro = authService.register(registro);

        LoginRequest login = LoginRequest.builder()
                .email("logintest@integracion.com")
                .password("passwordCorrecto123")
                .build();

        AuthResponse respuestaLogin = authService.login(login);

        assertNotNull(respuestaLogin.getToken());
        assertEquals(respuestaRegistro.getUsuarioId(), respuestaLogin.getUsuarioId());
        assertEquals("logintest@integracion.com", respuestaLogin.getEmail());
        assertEquals("USER", respuestaLogin.getRol());
        assertEquals("GRATUITO", respuestaLogin.getPlan());
    }

    @Test
    void loginDeberiaRechazarPasswordIncorrecto() {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Login Test2")
                .email("logintest2@integracion.com")
                .password("passwordCorrecto123")
                .fechaNacimiento("1995-05-15")
                .genero("FEMENINO")
                .build();
        authService.register(registro);

        LoginRequest loginIncorrecto = LoginRequest.builder()
                .email("logintest2@integracion.com")
                .password("password-equivocada")
                .build();

        assertThrows(RuntimeException.class, () -> {
            authService.login(loginIncorrecto);
        }, "No deberia permitirse login con password incorrecto");

        Long cantidadUsuarios = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM USUARIO WHERE email = :email AND activo = 1")
                .setParameter("email", "logintest2@integracion.com")
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadUsuarios, "El usuario deberia seguir existiendo y activo");
    }
}