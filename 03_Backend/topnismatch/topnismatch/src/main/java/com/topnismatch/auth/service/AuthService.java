package com.topnismatch.auth.service;

import com.topnismatch.auth.dto.*;
import com.topnismatch.auth.entity.Usuario;
import com.topnismatch.security.JwtService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    @PersistenceContext
    private EntityManager entityManager;

    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public AuthResponse register(RegisterRequest request) {

        Long count = entityManager.createQuery(
                        "SELECT COUNT(u) FROM Usuario u WHERE u.email = :email",
                        Long.class)
                .setParameter("email", request.getEmail())
                .getSingleResult();

        if (count > 0) {
            throw new RuntimeException("El email ya esta registrado");
        }

        Usuario usuario = Usuario.builder()
                .nombre(request.getNombre())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fechaNacimiento(LocalDate.parse(request.getFechaNacimiento(),
                        DateTimeFormatter.ofPattern("yyyy-MM-dd")))
                .genero(request.getGenero())
                .rol("USER")
                .activo(1)
                .emailVerificado(0)
                .build();

        entityManager.persist(usuario);
        entityManager.flush();

        // Crear suscripcion GRATUITO automaticamente
        entityManager.createNativeQuery(
                        "INSERT INTO SUSCRIPCION (suscripcion_id, usuario_id, plan, fecha_inicio, activo) " +
                                "VALUES (SEQ_SUSCRIPCION_ID.NEXTVAL, :userId, 'GRATUITO', SYSTIMESTAMP, 1)")
                .setParameter("userId", usuario.getUsuarioId())
                .executeUpdate();

        // Crear preferencias de notificacion automaticamente
        entityManager.createNativeQuery(
                        "INSERT INTO NOTIF_PREFERENCIAS (notif_pref_id, usuario_id) " +
                                "VALUES (SEQ_NOTIF_PREF_ID.NEXTVAL, :userId)")
                .setParameter("userId", usuario.getUsuarioId())
                .executeUpdate();

        String token = jwtService.generateToken(
                usuario.getUsuarioId(),
                usuario.getEmail(),
                usuario.getRol()
        );

        return AuthResponse.of(token, usuario.getUsuarioId(),
                usuario.getNombre(), usuario.getEmail(),
                usuario.getRol(), "GRATUITO");
    }

    public AuthResponse login(LoginRequest request) {

        List<Usuario> resultados = entityManager.createQuery(
                        "SELECT u FROM Usuario u WHERE u.email = :email AND u.activo = 1",
                        Usuario.class)
                .setParameter("email", request.getEmail())
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Credenciales invalidas");
        }

        Usuario usuario = resultados.get(0);

        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new RuntimeException("Credenciales invalidas");
        }

        List<String> planes = entityManager.createNativeQuery(
                        "SELECT plan FROM SUSCRIPCION WHERE usuario_id = :id AND activo = 1")
                .setParameter("id", usuario.getUsuarioId())
                .getResultList();

        String plan = planes.isEmpty() ? "GRATUITO" : (String) planes.get(0);

        String token = jwtService.generateToken(
                usuario.getUsuarioId(),
                usuario.getEmail(),
                usuario.getRol()
        );

        return AuthResponse.of(token, usuario.getUsuarioId(),
                usuario.getNombre(), usuario.getEmail(),
                usuario.getRol(), plan);
    }

    @Transactional
    public void logout(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtService.isTokenValid(token)) {
                String jti = jwtService.extractJti(token);
                Date expiracion = jwtService.extractExpiration(token);
                Long usuarioId = jwtService.extractUsuarioId(token);
                entityManager.createNativeQuery(
                                "INSERT INTO JWT_BLACKLIST (blacklist_id, token_jti, usuario_id, fecha_expiracion) " +
                                        "VALUES (SEQ_BLACKLIST_ID.NEXTVAL, :jti, :userId, :exp)")
                        .setParameter("jti", jti)
                        .setParameter("userId", usuarioId)
                        .setParameter("exp", expiracion)
                        .executeUpdate();
            }
        }
    }

    @Transactional
    public void forgotPassword(String email) {
        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT usuario_id FROM USUARIO WHERE email = :email AND activo = 1")
                .setParameter("email", email)
                .getResultList();

        if (!resultados.isEmpty()) {
            Object usuarioId = resultados.get(0);
            String token = UUID.randomUUID().toString();
            entityManager.createNativeQuery(
                            "INSERT INTO RESET_TOKEN (reset_id, usuario_id, token, usado, fecha_expiracion) " +
                                    "VALUES (SEQ_RESET_ID.NEXTVAL, :userId, :token, 0, SYSTIMESTAMP + INTERVAL '1' HOUR)")
                    .setParameter("userId", usuarioId)
                    .setParameter("token", token)
                    .executeUpdate();
        }
        // Siempre responde OK por seguridad (no revelar si el email existe)
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT usuario_id FROM RESET_TOKEN " +
                                "WHERE token = :token AND usado = 0 AND fecha_expiracion > SYSTIMESTAMP")
                .setParameter("token", request.getToken())
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Token invalido o expirado");
        }

        Object usuarioId = resultados.get(0);
        String nuevoHash = passwordEncoder.encode(request.getNuevaPassword());

        entityManager.createNativeQuery(
                        "UPDATE USUARIO SET password_hash = :hash WHERE usuario_id = :userId")
                .setParameter("hash", nuevoHash)
                .setParameter("userId", usuarioId)
                .executeUpdate();

        entityManager.createNativeQuery(
                        "UPDATE RESET_TOKEN SET usado = 1 WHERE token = :token")
                .setParameter("token", request.getToken())
                .executeUpdate();
    }

    @Transactional
    public void verifyEmail(String token) {
        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT usuario_id FROM RESET_TOKEN " +
                                "WHERE token = :token AND usado = 0 AND fecha_expiracion > SYSTIMESTAMP")
                .setParameter("token", token)
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Token de verificacion invalido o expirado");
        }

        Object usuarioId = resultados.get(0);

        entityManager.createNativeQuery(
                        "UPDATE USUARIO SET email_verificado = 1 WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .executeUpdate();

        entityManager.createNativeQuery(
                        "UPDATE RESET_TOKEN SET usado = 1 WHERE token = :token")
                .setParameter("token", token)
                .executeUpdate();
    }

    @Transactional
    public void deleteAccount(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Token no proporcionado");
        }

        String token = authHeader.substring(7);
        Long usuarioId = jwtService.extractUsuarioId(token);

        // Anonimizar email inmediatamente (libera constraint UNIQUE)
        String emailAnonimo = "deleted_" + usuarioId + "_" + UUID.randomUUID() + "@deleted.com";

        entityManager.createNativeQuery(
                        "UPDATE USUARIO SET activo = 0, email = :emailAnon WHERE usuario_id = :userId")
                .setParameter("emailAnon", emailAnonimo)
                .setParameter("userId", usuarioId)
                .executeUpdate();

        // Revocar token JWT actual
        logout(request);
    }
}