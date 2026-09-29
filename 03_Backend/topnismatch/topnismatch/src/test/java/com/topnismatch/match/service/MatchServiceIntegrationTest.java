package com.topnismatch.match.service;

import com.topnismatch.match.dto.LikeResponse;
import com.topnismatch.match.dto.MatchResponse;
import com.topnismatch.swipe.dto.SwipeResponse;
import com.topnismatch.swipe.service.SwipeService;
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
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@Transactional
class MatchServiceIntegrationTest {

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
    private MatchService matchService;

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
    void obtenerMisMatchesDeberiaRetornarMatchParaAmbosUsuarios() {
        Long usuarioA = crearUsuarioDePrueba("Match A", "matchA@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Match B", "matchB@integracion.com", "FEMENINO");

        SwipeResponse respuestaA = swipeService.darLike(usuarioA, usuarioB);
        assertFalse(respuestaA.getEsMatch(), "A->B solo no deberia generar match todavia");

        SwipeResponse respuestaB = swipeService.darLike(usuarioB, usuarioA);
        assertTrue(respuestaB.getEsMatch(), "B->A deberia generar match");

        List<MatchResponse> matchesDeA = matchService.obtenerMisMatches(usuarioA);
        assertEquals(1, matchesDeA.size(), "A deberia tener exactamente 1 match");
        assertEquals(usuarioB, matchesDeA.get(0).getOtroUsuarioId(), "El otro usuario del match de A deberia ser B");

        List<MatchResponse> matchesDeB = matchService.obtenerMisMatches(usuarioB);
        assertEquals(1, matchesDeB.size(), "B deberia tener exactamente 1 match");
        assertEquals(usuarioA, matchesDeB.get(0).getOtroUsuarioId(), "El otro usuario del match de B deberia ser A");
    }

    @Test
    void obtenerMatchPorIdDeberiaFuncionarParaAmbosParticipantes() {
        Long usuarioA = crearUsuarioDePrueba("Match A2", "matchA2@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Match B2", "matchB2@integracion.com", "FEMENINO");

        swipeService.darLike(usuarioA, usuarioB);
        SwipeResponse respuestaMatch = swipeService.darLike(usuarioB, usuarioA);
        Long matchId = respuestaMatch.getMatchId();
        assertNotNull(matchId, "Deberia haberse creado un matchId");

        MatchResponse desdeA = matchService.obtenerMatchPorId(matchId, usuarioA);
        assertEquals(matchId, desdeA.getMatchId());
        assertEquals(usuarioB, desdeA.getOtroUsuarioId());

        MatchResponse desdeB = matchService.obtenerMatchPorId(matchId, usuarioB);
        assertEquals(matchId, desdeB.getMatchId());
        assertEquals(usuarioA, desdeB.getOtroUsuarioId());
    }

    @Test
    void obtenerMatchPorIdDeberiaRechazarUsuarioAjeno() {
        Long usuarioA = crearUsuarioDePrueba("Match A3", "matchA3@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Match B3", "matchB3@integracion.com", "FEMENINO");
        Long usuarioC = crearUsuarioDePrueba("Match C3", "matchC3@integracion.com", "MASCULINO");

        swipeService.darLike(usuarioA, usuarioB);
        SwipeResponse respuestaMatch = swipeService.darLike(usuarioB, usuarioA);
        Long matchId = respuestaMatch.getMatchId();

        assertThrows(RuntimeException.class, () -> {
            matchService.obtenerMatchPorId(matchId, usuarioC);
        }, "Un usuario ajeno al match no deberia poder consultarlo");
    }

    @Test
    void eliminarMatchDeberiaHacerSoftDelete() {
        Long usuarioA = crearUsuarioDePrueba("Match A4", "matchA4@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Match B4", "matchB4@integracion.com", "FEMENINO");

        swipeService.darLike(usuarioA, usuarioB);
        SwipeResponse respuestaMatch = swipeService.darLike(usuarioB, usuarioA);
        Long matchId = respuestaMatch.getMatchId();

        List<MatchResponse> antesDeEliminar = matchService.obtenerMisMatches(usuarioA);
        assertEquals(1, antesDeEliminar.size(), "Antes de eliminar, A deberia tener 1 match activo");

        matchService.eliminarMatch(matchId, usuarioA);

        List<MatchResponse> despuesDeEliminar = matchService.obtenerMisMatches(usuarioA);
        assertEquals(0, despuesDeEliminar.size(), "Despues de eliminar, A no deberia tener matches activos");

        Integer activoEnBD = ((Number) entityManager.createNativeQuery(
                        "SELECT activo FROM MATCH_TOPNIS WHERE match_id = :matchId")
                .setParameter("matchId", matchId)
                .getSingleResult()).intValue();
        assertEquals(0, activoEnBD, "La fila del match deberia seguir existiendo pero con activo=0 (soft delete)");
    }
    @Test
    void obtenerQuienMeDioLikeDeberiaMostrarLikeUnilateral() {
        Long usuarioA = crearUsuarioDePrueba("Match A5", "matchA5@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Match B5", "matchB5@integracion.com", "FEMENINO");

        swipeService.darLike(usuarioA, usuarioB);

        List<LikeResponse> likesDeB = matchService.obtenerQuienMeDioLike(usuarioB);
        assertEquals(1, likesDeB.size(), "B deberia ver 1 like recibido de A");

        LikeResponse like = likesDeB.get(0);
        assertEquals(usuarioA, like.getUsuarioId());
        assertEquals("LIKE", like.getTipoLike());
        assertNotNull(like.getFechaLike());

        List<LikeResponse> likesDeA = matchService.obtenerQuienMeDioLike(usuarioA);
        assertTrue(likesDeA.isEmpty(), "A no deberia tener likes recibidos, ya que B no le dio like todavia");
    }
}