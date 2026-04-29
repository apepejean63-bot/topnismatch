package com.topnismatch.match.service;

import com.topnismatch.match.dto.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MatchService {

    @PersistenceContext
    private EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public List<MatchResponse> obtenerMisMatches(Long usuarioId) {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT m.match_id, m.usuario1_id, m.usuario2_id, " +
                                "m.compatibilidad, m.fecha_match, m.activo " +
                                "FROM MATCH_TOPNIS m " +
                                "WHERE (m.usuario1_id = :userId OR m.usuario2_id = :userId) " +
                                "AND m.activo = 1 " +
                                "ORDER BY m.fecha_match DESC")
                .setParameter("userId", usuarioId)
                .getResultList();

        List<MatchResponse> matches = new ArrayList<>();

        for (Object[] row : resultados) {
            Long matchId = ((Number) row[0]).longValue();
            Long usuario1Id = ((Number) row[1]).longValue();
            Long usuario2Id = ((Number) row[2]).longValue();
            Double compatibilidad = ((Number) row[3]).doubleValue();
            LocalDateTime fechaMatch = ((java.sql.Timestamp) row[4]).toLocalDateTime();

            Long otroUsuarioId = usuario1Id.equals(usuarioId) ? usuario2Id : usuario1Id;
            String nombre = obtenerNombreUsuario(otroUsuarioId);
            String fotoUrl = obtenerFotoPrincipalUrl(otroUsuarioId);

            matches.add(MatchResponse.builder()
                    .matchId(matchId)
                    .otroUsuarioId(otroUsuarioId)
                    .otroUsuarioNombre(nombre)
                    .otroUsuarioFotoUrl(fotoUrl)
                    .compatibilidad(compatibilidad)
                    .fechaMatch(fechaMatch)
                    .activo(true)
                    .build());
        }

        return matches;
    }

    public MatchResponse obtenerMatchPorId(Long matchId, Long usuarioId) {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT m.match_id, m.usuario1_id, m.usuario2_id, " +
                                "m.compatibilidad, m.fecha_match, m.activo " +
                                "FROM MATCH_TOPNIS m " +
                                "WHERE m.match_id = :matchId " +
                                "AND (m.usuario1_id = :userId OR m.usuario2_id = :userId)")
                .setParameter("matchId", matchId)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Match no encontrado o no tienes acceso");
        }

        Object[] row = resultados.get(0);
        Long usuario1Id = ((Number) row[1]).longValue();
        Long usuario2Id = ((Number) row[2]).longValue();
        Double compatibilidad = ((Number) row[3]).doubleValue();
        LocalDateTime fechaMatch = ((java.sql.Timestamp) row[4]).toLocalDateTime();

        Long otroUsuarioId = usuario1Id.equals(usuarioId) ? usuario2Id : usuario1Id;
        String nombre = obtenerNombreUsuario(otroUsuarioId);
        String fotoUrl = obtenerFotoPrincipalUrl(otroUsuarioId);

        return MatchResponse.builder()
                .matchId(matchId)
                .otroUsuarioId(otroUsuarioId)
                .otroUsuarioNombre(nombre)
                .otroUsuarioFotoUrl(fotoUrl)
                .compatibilidad(compatibilidad)
                .fechaMatch(fechaMatch)
                .activo(true)
                .build();
    }

    @Transactional
    public void eliminarMatch(Long matchId, Long usuarioId) {

        List<Object> resultados = entityManager.createNativeQuery(
                        "SELECT match_id FROM MATCH_TOPNIS " +
                                "WHERE match_id = :matchId " +
                                "AND (usuario1_id = :userId OR usuario2_id = :userId)")
                .setParameter("matchId", matchId)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Match no encontrado o no tienes acceso");
        }

        entityManager.createNativeQuery(
                        "UPDATE MATCH_TOPNIS SET activo = 0 WHERE match_id = :matchId")
                .setParameter("matchId", matchId)
                .executeUpdate();
    }

    @SuppressWarnings("unchecked")
    public List<LikeResponse> obtenerQuienMeDioLike(Long usuarioId) {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT la.usuario_origen, u.nombre, la.tipo, la.fecha " +
                                "FROM LIKE_ACCION la " +
                                "JOIN USUARIO u ON la.usuario_origen = u.usuario_id " +
                                "WHERE la.usuario_destino = :userId " +
                                "AND la.tipo IN ('LIKE', 'SUPERLIKE') " +
                                "AND la.usuario_origen NOT IN (" +
                                "   SELECT la2.usuario_destino FROM LIKE_ACCION la2 " +
                                "   WHERE la2.usuario_origen = :userId" +
                                ") " +
                                "ORDER BY la.fecha DESC")
                .setParameter("userId", usuarioId)
                .getResultList();

        List<LikeResponse> likes = new ArrayList<>();

        for (Object[] row : resultados) {
            Long origenId = ((Number) row[0]).longValue();
            String nombre = (String) row[1];
            String tipo = (String) row[2];
            LocalDateTime fecha = ((java.sql.Timestamp) row[3]).toLocalDateTime();
            String fotoUrl = obtenerFotoPrincipalUrl(origenId);

            likes.add(LikeResponse.builder()
                    .usuarioId(origenId)
                    .nombre(nombre)
                    .fotoUrl(fotoUrl)
                    .tipoLike(tipo)
                    .fechaLike(fecha)
                    .build());
        }

        return likes;
    }

    private String obtenerNombreUsuario(Long usuarioId) {
        List<String> nombres = entityManager.createNativeQuery(
                        "SELECT nombre FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();
        return nombres.isEmpty() ? "" : nombres.get(0);
    }

    private String obtenerFotoPrincipalUrl(Long usuarioId) {
        List<String> urls = entityManager.createNativeQuery(
                        "SELECT f.url FROM FOTO f " +
                                "JOIN PERFIL p ON p.foto_principal_id = f.foto_id " +
                                "WHERE p.usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();
        return urls.isEmpty() ? null : urls.get(0);
    }
}