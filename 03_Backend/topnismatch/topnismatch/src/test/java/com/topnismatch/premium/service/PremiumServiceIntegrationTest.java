package com.topnismatch.premium.service;

import com.topnismatch.auth.dto.AuthResponse;
import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.service.AuthService;
import com.topnismatch.premium.dto.BoostResponse;
import com.topnismatch.premium.dto.SuscripcionResponse;
import com.topnismatch.premium.dto.UpgradeRequest;
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
class PremiumServiceIntegrationTest {

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
    private PremiumService premiumService;

    @Autowired
    private AuthService authService;

    @Autowired
    private EntityManager entityManager;

    private Long crearUsuarioRegistrado(String email) {
        RegisterRequest request = RegisterRequest.builder()
                .nombre("Premium Test")
                .email(email)
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        AuthResponse respuesta = authService.register(request);
        return respuesta.getUsuarioId();
    }

    @Test
    void upgradePremiumMensualDeberiaActivarSuscripcion() {
        Long usuarioId = crearUsuarioRegistrado("premiumtest@integracion.com");

        SuscripcionResponse antesDelUpgrade = premiumService.obtenerSuscripcion(usuarioId);
        assertEquals("GRATUITO", antesDelUpgrade.getPlan());
        assertFalse(antesDelUpgrade.getEsPremium());

        UpgradeRequest request = new UpgradeRequest();
        request.setPlan("PREMIUM_MENSUAL");
        request.setReciboStore("recibo-de-prueba-123");

        SuscripcionResponse respuesta = premiumService.upgradePremium(usuarioId, request);

        assertEquals("PREMIUM_MENSUAL", respuesta.getPlan());
        assertTrue(respuesta.getEsPremium());
        assertNotNull(respuesta.getFechaFin());
        assertTrue(respuesta.getDiasRestantes() >= 29 && respuesta.getDiasRestantes() <= 30,
                "Deberian quedar aproximadamente 30 dias de Premium mensual");

        String rolEnBD = (String) entityManager.createNativeQuery(
                        "SELECT rol FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult();
        assertEquals("PREMIUM", rolEnBD, "El rol del usuario deberia actualizarse a PREMIUM");
    }
    @Test
    void activarBoostConUsuarioPremiumDeberiaFuncionar() {
        Long usuarioId = crearUsuarioRegistrado("premiumboost@integracion.com");

        UpgradeRequest upgradeRequest = new UpgradeRequest();
        upgradeRequest.setPlan("PREMIUM_MENSUAL");
        upgradeRequest.setReciboStore("recibo-boost-test");
        premiumService.upgradePremium(usuarioId, upgradeRequest);

        BoostResponse respuesta = premiumService.activarBoost(usuarioId);

        assertNotNull(respuesta.getBoostId());
        assertTrue(respuesta.getActivo());
        assertNotNull(respuesta.getFechaActivacion());
        assertNotNull(respuesta.getFechaFin());

        long minutosDeDuracion = java.time.temporal.ChronoUnit.MINUTES.between(
                respuesta.getFechaActivacion(), respuesta.getFechaFin());
        assertTrue(minutosDeDuracion >= 29 && minutosDeDuracion <= 30,
                "El boost deberia durar aproximadamente 30 minutos");

        Long usuarioEnBD = ((Number) entityManager.createNativeQuery(
                        "SELECT usuario_id FROM BOOST_HISTORIAL WHERE boost_id = :boostId")
                .setParameter("boostId", respuesta.getBoostId())
                .getSingleResult()).longValue();
        assertEquals(usuarioId.longValue(), usuarioEnBD, "El boost deberia pertenecer al usuario correcto");
    }
    @Test
    void activarBoostConUsuarioGratuitoDeberiaSerRechazado() {
        Long usuarioId = crearUsuarioRegistrado("premiumboostgratuito@integracion.com");

        SuscripcionResponse suscripcion = premiumService.obtenerSuscripcion(usuarioId);
        assertEquals("GRATUITO", suscripcion.getPlan(), "El usuario deberia seguir siendo GRATUITO");

        assertThrows(RuntimeException.class, () -> {
            premiumService.activarBoost(usuarioId);
        }, "Un usuario GRATUITO no deberia poder activar boost");

        Long cantidadBoosts = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM BOOST_HISTORIAL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(0L, cantidadBoosts, "No deberia haberse creado ningun boost para el usuario gratuito");
    }
}