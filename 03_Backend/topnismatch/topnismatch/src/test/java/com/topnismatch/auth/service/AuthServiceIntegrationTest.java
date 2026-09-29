package com.topnismatch.auth.service;

import com.topnismatch.auth.dto.AuthResponse;
import com.topnismatch.auth.dto.LoginRequest;
import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.dto.ResetPasswordRequest;
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
    @Test
    void verifyEmailDeberiaMarcarEmailComoVerificado() {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Verify Test")
                .email("verifytest@integracion.com")
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        AuthResponse respuestaRegistro = authService.register(registro);

        Integer verificadoAntes = ((Number) entityManager.createNativeQuery(
                        "SELECT email_verificado FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", respuestaRegistro.getUsuarioId())
                .getSingleResult()).intValue();
        assertEquals(0, verificadoAntes, "El email no deberia estar verificado recien registrado");

        String tokenVerificacion = "token-verificacion-prueba-123";
        entityManager.createNativeQuery(
                        "INSERT INTO RESET_TOKEN (reset_id, usuario_id, token, usado, fecha_expiracion) " +
                                "VALUES (NEXTVAL('seq_reset_id'), :userId, :token, 0, NOW() + INTERVAL '1 hour')")
                .setParameter("userId", respuestaRegistro.getUsuarioId())
                .setParameter("token", tokenVerificacion)
                .executeUpdate();

        authService.verifyEmail(tokenVerificacion);

        Integer verificadoDespues = ((Number) entityManager.createNativeQuery(
                        "SELECT email_verificado FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", respuestaRegistro.getUsuarioId())
                .getSingleResult()).intValue();
        assertEquals(1, verificadoDespues, "El email deberia quedar verificado");

        Integer tokenUsado = ((Number) entityManager.createNativeQuery(
                        "SELECT usado FROM RESET_TOKEN WHERE token = :token")
                .setParameter("token", tokenVerificacion)
                .getSingleResult()).intValue();
        assertEquals(1, tokenUsado, "El token deberia quedar marcado como usado");
    }

    @Test
    void verifyEmailDeberiaRechazarTokenInvalido() {
        assertThrows(RuntimeException.class, () -> {
            authService.verifyEmail("token-que-no-existe-nunca");
        }, "Deberia rechazar un token de verificacion que no existe");
    }
    @Test
    void flujoCompletoDeRecuperarPasswordDeberiaFuncionar() {
        RegisterRequest registro = RegisterRequest.builder()
                .nombre("Reset Test")
                .email("resettest@integracion.com")
                .password("passwordVieja123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        authService.register(registro);

        authService.forgotPassword("resettest@integracion.com");

        String tokenGenerado = (String) entityManager.createNativeQuery(
                        "SELECT token FROM RESET_TOKEN rt JOIN USUARIO u ON rt.usuario_id = u.usuario_id " +
                                "WHERE u.email = :email ORDER BY rt.fecha_creacion DESC")
                .setParameter("email", "resettest@integracion.com")
                .setMaxResults(1)
                .getSingleResult();
        assertNotNull(tokenGenerado, "Deberia haberse generado un token de recuperacion");

        ResetPasswordRequest resetRequest = new ResetPasswordRequest();
        resetRequest.setToken(tokenGenerado);
        resetRequest.setNuevaPassword("passwordNueva456");
        authService.resetPassword(resetRequest);
        entityManager.clear();

        LoginRequest loginConVieja = LoginRequest.builder()
                .email("resettest@integracion.com")
                .password("passwordVieja123")
                .build();
        assertThrows(RuntimeException.class, () -> {
            authService.login(loginConVieja);
        }, "La contrasena vieja ya no deberia funcionar");

        LoginRequest loginConNueva = LoginRequest.builder()
                .email("resettest@integracion.com")
                .password("passwordNueva456")
                .build();
        AuthResponse respuestaLogin = authService.login(loginConNueva);
        assertNotNull(respuestaLogin.getToken(), "El login con la nueva contrasena deberia funcionar");
    }
}