package com.topnismatch.chat.service;

import com.topnismatch.chat.dto.*;
import com.topnismatch.chat.entity.Mensaje;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional
    public MensajeResponse enviarMensaje(Long matchId, Long emisorId,
                                         MensajeRequest request) {
        List<Object> match = entityManager.createNativeQuery(
                        "SELECT match_id FROM MATCH_TOPNIS " +
                                "WHERE match_id = :matchId AND activo = 1 " +
                                "AND (usuario1_id = :userId OR usuario2_id = :userId)")
                .setParameter("matchId", matchId)
                .setParameter("userId", emisorId)
                .getResultList();

        if (match.isEmpty()) {
            throw new RuntimeException("Match no encontrado o no tienes acceso");
        }

        List<Object[]> matchInfo = entityManager.createNativeQuery(
                        "SELECT usuario1_id, usuario2_id FROM MATCH_TOPNIS " +
                                "WHERE match_id = :matchId")
                .setParameter("matchId", matchId)
                .getResultList();

        Long otroUsuarioId = null;
        if (!matchInfo.isEmpty()) {
            Object[] row = matchInfo.get(0);
            Long u1 = ((Number) row[0]).longValue();
            Long u2 = ((Number) row[1]).longValue();
            otroUsuarioId = u1.equals(emisorId) ? u2 : u1;
        }

        if (otroUsuarioId != null) {
            List<Object> bloqueo = entityManager.createNativeQuery(
                            "SELECT bloqueo_id FROM BLOQUEO " +
                                    "WHERE (usuario_bloqueador = :userId AND usuario_bloqueado = :otroId) " +
                                    "OR (usuario_bloqueador = :otroId AND usuario_bloqueado = :userId)")
                    .setParameter("userId", emisorId)
                    .setParameter("otroId", otroUsuarioId)
                    .getResultList();

            if (!bloqueo.isEmpty()) {
                throw new RuntimeException("No puedes enviar mensajes a este usuario");
            }
        }

        Mensaje mensaje = Mensaje.builder()
                .matchId(matchId)
                .emisorId(emisorId)
                .contenido(request.getContenido())
                .estado("ENVIADO")
                .build();

        entityManager.persist(mensaje);
        entityManager.flush();

        String emisorNombre = obtenerNombreUsuario(emisorId);
        return buildMensajeResponse(mensaje, emisorNombre);
    }

    public List<MensajeResponse> obtenerHistorial(Long matchId, Long usuarioId) {

        List<Object> match = entityManager.createNativeQuery(
                        "SELECT match_id FROM MATCH_TOPNIS " +
                                "WHERE match_id = :matchId " +
                                "AND (usuario1_id = :userId OR usuario2_id = :userId)")
                .setParameter("matchId", matchId)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (match.isEmpty()) {
            throw new RuntimeException("Match no encontrado o no tienes acceso");
        }

        List<Mensaje> mensajes = entityManager.createQuery(
                        "SELECT m FROM Mensaje m WHERE m.matchId = :matchId " +
                                "ORDER BY m.fechaEnvio ASC",
                        Mensaje.class)
                .setParameter("matchId", matchId)
                .getResultList();

        return mensajes.stream()
                .map(m -> buildMensajeResponse(m, obtenerNombreUsuario(m.getEmisorId())))
                .collect(Collectors.toList());
    }

    @Transactional
    public void marcarComoLeido(Long matchId, Long usuarioId) {

        List<Object> match = entityManager.createNativeQuery(
                        "SELECT match_id FROM MATCH_TOPNIS " +
                                "WHERE match_id = :matchId " +
                                "AND (usuario1_id = :userId OR usuario2_id = :userId)")
                .setParameter("matchId", matchId)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (match.isEmpty()) {
            throw new RuntimeException("Match no encontrado o no tienes acceso");
        }

        entityManager.createNativeQuery(
                        "UPDATE MENSAJE SET estado = 'LEIDO' " +
                                "WHERE match_id = :matchId " +
                                "AND emisor_id != :userId " +
                                "AND estado != 'LEIDO'")
                .setParameter("matchId", matchId)
                .setParameter("userId", usuarioId)
                .executeUpdate();
    }

    @Transactional
    public void bloquearUsuario(Long usuarioBloqueadorId, Long usuarioBloqueadoId) {

        List<Object> existente = entityManager.createNativeQuery(
                        "SELECT bloqueo_id FROM BLOQUEO " +
                                "WHERE usuario_bloqueador = :bloqueador " +
                                "AND usuario_bloqueado = :bloqueado")
                .setParameter("bloqueador", usuarioBloqueadorId)
                .setParameter("bloqueado", usuarioBloqueadoId)
                .getResultList();

        if (!existente.isEmpty()) {
            throw new RuntimeException("Ya bloqueaste a este usuario");
        }

        entityManager.createNativeQuery(
                        "INSERT INTO BLOQUEO (bloqueo_id, usuario_bloqueador, usuario_bloqueado) " +
                                "VALUES (NEXTVAL('seq_bloqueo_id'), :bloqueador, :bloqueado)")
                .setParameter("bloqueador", usuarioBloqueadorId)
                .setParameter("bloqueado", usuarioBloqueadoId)
                .executeUpdate();

        entityManager.createNativeQuery(
                        "UPDATE MATCH_TOPNIS SET activo = 0 " +
                                "WHERE (usuario1_id = :u1 AND usuario2_id = :u2) " +
                                "OR (usuario1_id = :u2 AND usuario2_id = :u1)")
                .setParameter("u1", usuarioBloqueadorId)
                .setParameter("u2", usuarioBloqueadoId)
                .executeUpdate();
    }

    @Transactional
    public void reportarUsuario(Long denuncianteId, Long denunciadoId,
                                BlockReportRequest request) {

        entityManager.createNativeQuery(
                        "INSERT INTO REPORTE (reporte_id, usuario_denunciante, usuario_denunciado, " +
                                "categoria, descripcion, estado) " +
                                "VALUES (NEXTVAL('seq_reporte_id'), :denunciante, :denunciado, " +
                                ":categoria, :descripcion, 'PENDIENTE')")
                .setParameter("denunciante", denuncianteId)
                .setParameter("denunciado", denunciadoId)
                .setParameter("categoria", request.getCategoria() != null ?
                        request.getCategoria() : "OTRO")
                .setParameter("descripcion", request.getDescripcion())
                .executeUpdate();
    }

    private MensajeResponse buildMensajeResponse(Mensaje mensaje, String emisorNombre) {
        return MensajeResponse.builder()
                .mensajeId(mensaje.getMensajeId())
                .matchId(mensaje.getMatchId())
                .emisorId(mensaje.getEmisorId())
                .emisorNombre(emisorNombre)
                .contenido(mensaje.getContenido())
                .estado(mensaje.getEstado())
                .fechaEnvio(mensaje.getFechaEnvio())
                .fechaLeido(mensaje.getFechaLeido())
                .build();
    }

    private String obtenerNombreUsuario(Long usuarioId) {
        List<String> nombres = entityManager.createNativeQuery(
                        "SELECT nombre FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();
        return nombres.isEmpty() ? "" : nombres.get(0);
    }
}