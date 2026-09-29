package com.topnismatch.swipe.service;

import com.topnismatch.swipe.dto.SwipeResponse;
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

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@Transactional
class SwipeServiceIntegrationTest {

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
    private EntityManager entityManager;

    private Long crearUsuarioDePrueba(String nombre, String email, String genero) {
        return ((Number) entityManager.createNativeQuery(
                        "INSERT INTO USUARIO (nombre, email, password_hash, fecha_nacimiento, genero) " +
                                "VALUES (:nombre, :email, :pass, :fecha, :genero) RETURNING usuario_id")
                .setParameter("nombre", nombre)
                .setParameter("email", email)
                .setParameter("pass", "hash-de-prueba")
                .setParameter("fecha", LocalDate.of(1995, 1, 1))
                .setParameter("genero", genero)
                .getSingleResult()).longValue();
    }

    @Test
    void likeMutuoDeberiaCrearMatch() {
        Long usuarioA = crearUsuarioDePrueba("Test A", "testA@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Test B", "testB@integracion.com", "FEMENINO");

        SwipeResponse respuesta1 = swipeService.darLike(usuarioA, usuarioB);
        assertFalse(respuesta1.getEsMatch(), "A->B solo no deberia generar match todavia");
        assertNull(respuesta1.getMatchId());

        SwipeResponse respuesta2 = swipeService.darLike(usuarioB, usuarioA);
        assertTrue(respuesta2.getEsMatch(), "B->A deberia generar match porque A ya habia dado like antes");
        assertNotNull(respuesta2.getMatchId());
    }

    @Test
    void likeDuplicadoDeberiaSerRechazado() {
        Long usuarioA = crearUsuarioDePrueba("Test A2", "testA2@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Test B2", "testB2@integracion.com", "FEMENINO");

        swipeService.darLike(usuarioA, usuarioB);

        assertThrows(RuntimeException.class, () -> {
            swipeService.darLike(usuarioA, usuarioB);
        }, "Deberia lanzar excepcion al repetir el like sobre el mismo usuario");
    }

    @Test
    void dislikeNoDeberiaGenerarMatch() {
        Long usuarioA = crearUsuarioDePrueba("Test A3", "testA3@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Test B3", "testB3@integracion.com", "FEMENINO");

        SwipeResponse respuesta = swipeService.darDislike(usuarioA, usuarioB);

        assertEquals("DISLIKE", respuesta.getResultado());
        assertFalse(respuesta.getEsMatch());
        assertNull(respuesta.getMatchId());
    }

    @Test
    void superlikeConLikeReciprocoDeberiaCrearMatch() {
        Long usuarioA = crearUsuarioDePrueba("Test A4", "testA4@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Test B4", "testB4@integracion.com", "FEMENINO");

        SwipeResponse respuestaSuperlike = swipeService.darSuperlike(usuarioA, usuarioB);
        assertFalse(respuestaSuperlike.getEsMatch(), "El superlike solo no deberia generar match todavia");
        assertNull(respuestaSuperlike.getMatchId());
        assertEquals("SUPERLIKE", respuestaSuperlike.getResultado());

        SwipeResponse respuestaLike = swipeService.darLike(usuarioB, usuarioA);
        assertTrue(respuestaLike.getEsMatch(), "El like reciproco tras un superlike deberia generar match");
        assertNotNull(respuestaLike.getMatchId());
    }
}