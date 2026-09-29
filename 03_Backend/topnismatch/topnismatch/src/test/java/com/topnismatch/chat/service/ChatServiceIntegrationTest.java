package com.topnismatch.chat.service;

import com.topnismatch.chat.dto.BlockReportRequest;
import com.topnismatch.chat.dto.MensajeRequest;
import com.topnismatch.chat.dto.MensajeResponse;
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
class ChatServiceIntegrationTest {

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
    private ChatService chatService;

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

    private Long crearMatchDePrueba(Long usuarioA, Long usuarioB) {
        swipeService.darLike(usuarioA, usuarioB);
        SwipeResponse respuesta = swipeService.darLike(usuarioB, usuarioA);
        return respuesta.getMatchId();
    }

    @Test
    void enviarMensajeDeberiaGuardarloCorrectamente() {
        Long usuarioA = crearUsuarioDePrueba("Chat A", "chatA@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B", "chatB@integracion.com", "FEMENINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);
        assertNotNull(matchId, "Deberia haberse creado un match valido");

        MensajeRequest request = new MensajeRequest();
        request.setContenido("Hola, como estas?");

        MensajeResponse respuesta = chatService.enviarMensaje(matchId, usuarioA, request);

        assertNotNull(respuesta.getMensajeId());
        assertEquals(matchId, respuesta.getMatchId());
        assertEquals(usuarioA, respuesta.getEmisorId());
        assertEquals("Hola, como estas?", respuesta.getContenido());
        assertEquals("ENVIADO", respuesta.getEstado());
        assertNotNull(respuesta.getFechaEnvio());
        assertNull(respuesta.getFechaLeido(), "Un mensaje recien enviado no deberia tener fecha de leido");
    }
    @Test
    void obtenerHistorialDeberiaRetornarMensajesEnOrden() {
        Long usuarioA = crearUsuarioDePrueba("Chat A2", "chatA2@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B2", "chatB2@integracion.com", "FEMENINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        MensajeRequest msg1 = new MensajeRequest();
        msg1.setContenido("Hola B");
        chatService.enviarMensaje(matchId, usuarioA, msg1);

        MensajeRequest msg2 = new MensajeRequest();
        msg2.setContenido("Hola A");
        chatService.enviarMensaje(matchId, usuarioB, msg2);

        MensajeRequest msg3 = new MensajeRequest();
        msg3.setContenido("Como estas?");
        chatService.enviarMensaje(matchId, usuarioA, msg3);

        List<MensajeResponse> historial = chatService.obtenerHistorial(matchId, usuarioA);

        assertEquals(3, historial.size(), "Deberian existir exactamente 3 mensajes");
        assertEquals("Hola B", historial.get(0).getContenido());
        assertEquals(usuarioA, historial.get(0).getEmisorId());
        assertEquals("Hola A", historial.get(1).getContenido());
        assertEquals(usuarioB, historial.get(1).getEmisorId());
        assertEquals("Como estas?", historial.get(2).getContenido());
        assertEquals(usuarioA, historial.get(2).getEmisorId());
    }

    @Test
    void obtenerHistorialDeberiaRechazarUsuarioAjeno() {
        Long usuarioA = crearUsuarioDePrueba("Chat A3", "chatA3@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B3", "chatB3@integracion.com", "FEMENINO");
        Long usuarioC = crearUsuarioDePrueba("Chat C3", "chatC3@integracion.com", "MASCULINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        assertThrows(RuntimeException.class, () -> {
            chatService.obtenerHistorial(matchId, usuarioC);
        }, "Un usuario ajeno al match no deberia poder ver el historial");
    }
    @Test
    void marcarComoLeidoDeberiaActualizarEstadoYFecha() {
        Long usuarioA = crearUsuarioDePrueba("Chat A4", "chatA4@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B4", "chatB4@integracion.com", "FEMENINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        MensajeRequest mensajeRequest = new MensajeRequest();
        mensajeRequest.setContenido("Mensaje de A para B");
        MensajeResponse mensajeEnviado = chatService.enviarMensaje(matchId, usuarioA, mensajeRequest);

        assertEquals("ENVIADO", mensajeEnviado.getEstado());
        assertNull(mensajeEnviado.getFechaLeido());

        chatService.marcarComoLeido(matchId, usuarioB);
        entityManager.clear();

        List<MensajeResponse> historial = chatService.obtenerHistorial(matchId, usuarioA);
        assertEquals(1, historial.size(), "Deberia seguir existiendo un solo mensaje, no uno nuevo");

        MensajeResponse mensajeActualizado = historial.get(0);
        assertEquals(mensajeEnviado.getMensajeId(), mensajeActualizado.getMensajeId(),
                "Deberia ser el mismo mensaje, no uno nuevo");
        assertEquals("LEIDO", mensajeActualizado.getEstado());
        assertNotNull(mensajeActualizado.getFechaLeido(), "Deberia tener fecha de leido despues de marcarlo");
    }
    @Test
    void bloquearUsuarioDeberiaRegistrarBloqueoYDesactivarMatch() {
        Long usuarioA = crearUsuarioDePrueba("Chat A5", "chatA5@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B5", "chatB5@integracion.com", "FEMENINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        chatService.bloquearUsuario(usuarioA, usuarioB);

        Integer cantidadBloqueos = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM BLOQUEO WHERE usuario_bloqueador = :bloqueador AND usuario_bloqueado = :bloqueado")
                .setParameter("bloqueador", usuarioA)
                .setParameter("bloqueado", usuarioB)
                .getSingleResult()).intValue();
        assertEquals(1, cantidadBloqueos, "Deberia existir exactamente 1 registro de bloqueo");

        Integer activoEnBD = ((Number) entityManager.createNativeQuery(
                        "SELECT activo FROM MATCH_TOPNIS WHERE match_id = :matchId")
                .setParameter("matchId", matchId)
                .getSingleResult()).intValue();
        assertEquals(0, activoEnBD, "El match deberia quedar desactivado al bloquear al otro usuario");
    }

    @Test
    void bloquearUsuarioDosVecesDeberiaSerRechazado() {
        Long usuarioA = crearUsuarioDePrueba("Chat A6", "chatA6@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B6", "chatB6@integracion.com", "FEMENINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        chatService.bloquearUsuario(usuarioA, usuarioB);

        assertThrows(RuntimeException.class, () -> {
            chatService.bloquearUsuario(usuarioA, usuarioB);
        }, "No deberia permitirse bloquear dos veces al mismo usuario");
    }
    @Test
    void reportarUsuarioDeberiaPersistirElReporte() {
        Long usuarioA = crearUsuarioDePrueba("Chat A7", "chatA7@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B7", "chatB7@integracion.com", "FEMENINO");
        crearMatchDePrueba(usuarioA, usuarioB);

        BlockReportRequest request = new BlockReportRequest();
        request.setCategoria("CONTENIDO_INAPROPIADO");
        request.setDescripcion("Reporte de prueba");

        chatService.reportarUsuario(usuarioA, usuarioB, request);

        Object[] fila = (Object[]) entityManager.createNativeQuery(
                        "SELECT usuario_denunciante, usuario_denunciado, categoria, descripcion, estado " +
                                "FROM REPORTE WHERE usuario_denunciante = :denunciante AND usuario_denunciado = :denunciado")
                .setParameter("denunciante", usuarioA)
                .setParameter("denunciado", usuarioB)
                .getSingleResult();

        assertEquals(usuarioA.longValue(), ((Number) fila[0]).longValue());
        assertEquals(usuarioB.longValue(), ((Number) fila[1]).longValue());
        assertEquals("CONTENIDO_INAPROPIADO", fila[2]);
        assertEquals("Reporte de prueba", fila[3]);
        assertEquals("PENDIENTE", fila[4]);
    }

    @Test
    void enviarMensajeDeberiaRechazarUsuarioAjenoAlMatch() {
        Long usuarioA = crearUsuarioDePrueba("Chat A8", "chatA8@integracion.com", "MASCULINO");
        Long usuarioB = crearUsuarioDePrueba("Chat B8", "chatB8@integracion.com", "FEMENINO");
        Long usuarioC = crearUsuarioDePrueba("Chat C8", "chatC8@integracion.com", "MASCULINO");
        Long matchId = crearMatchDePrueba(usuarioA, usuarioB);

        MensajeRequest request = new MensajeRequest();
        request.setContenido("Mensaje de un intruso");

        assertThrows(RuntimeException.class, () -> {
            chatService.enviarMensaje(matchId, usuarioC, request);
        }, "Un usuario ajeno al match no deberia poder enviar mensajes ahi");

        Long cantidadMensajes = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM MENSAJE WHERE match_id = :matchId")
                .setParameter("matchId", matchId)
                .getSingleResult()).longValue();
        assertEquals(0L, cantidadMensajes, "No deberia haberse guardado ningun mensaje");
    }
}