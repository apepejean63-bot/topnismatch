package com.topnismatch.premium.service;

import com.topnismatch.premium.dto.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PremiumService {

    @PersistenceContext
    private EntityManager entityManager;

    public SuscripcionResponse obtenerSuscripcion(Long usuarioId) {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT suscripcion_id, plan, fecha_inicio, fecha_fin, activo " +
                                "FROM SUSCRIPCION WHERE usuario_id = :userId AND activo = 1")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (resultados.isEmpty()) {
            return SuscripcionResponse.builder()
                    .plan("GRATUITO")
                    .activo(true)
                    .esPremium(false)
                    .diasRestantes(0L)
                    .build();
        }

        Object[] row = resultados.get(0);
        Long suscripcionId = ((Number) row[0]).longValue();
        String plan = (String) row[1];
        LocalDateTime fechaInicio = ((java.sql.Timestamp) row[2]).toLocalDateTime();
        LocalDateTime fechaFin = row[3] != null ?
                ((java.sql.Timestamp) row[3]).toLocalDateTime() : null;

        boolean esPremium = false;
        long diasRestantes = 0;

        if (!plan.equals("GRATUITO") && fechaFin != null) {
            if (LocalDateTime.now().isAfter(fechaFin)) {
                degradarAGratuito(usuarioId);
                plan = "GRATUITO";
                esPremium = false;
            } else {
                esPremium = true;
                diasRestantes = ChronoUnit.DAYS.between(LocalDateTime.now(), fechaFin);
            }
        }

        return SuscripcionResponse.builder()
                .suscripcionId(suscripcionId)
                .plan(plan)
                .fechaInicio(fechaInicio)
                .fechaFin(fechaFin)
                .activo(true)
                .esPremium(esPremium)
                .diasRestantes(diasRestantes)
                .build();
    }

    @Transactional
    public SuscripcionResponse upgradePremium(Long usuarioId, UpgradeRequest request) {

        int dias = request.getPlan().equals("PREMIUM_MENSUAL") ? 30 : 365;

        List<Object[]> premiumActivo = entityManager.createNativeQuery(
                        "SELECT suscripcion_id, fecha_fin FROM SUSCRIPCION " +
                                "WHERE usuario_id = :userId AND activo = 1 " +
                                "AND plan != 'GRATUITO' AND fecha_fin > NOW()")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (!premiumActivo.isEmpty()) {
            Object[] row = premiumActivo.get(0);
            Long suscripcionId = ((Number) row[0]).longValue();
            LocalDateTime fechaFinActual = ((java.sql.Timestamp) row[1]).toLocalDateTime();
            LocalDateTime nuevaFechaFin = fechaFinActual.plusDays(dias);

            entityManager.createNativeQuery(
                            "UPDATE SUSCRIPCION SET fecha_fin = :fechaFin, plan = :plan, " +
                                    "recibo_store = :recibo WHERE suscripcion_id = :id")
                    .setParameter("fechaFin", nuevaFechaFin)
                    .setParameter("plan", request.getPlan())
                    .setParameter("recibo", request.getReciboStore())
                    .setParameter("id", suscripcionId)
                    .executeUpdate();
        } else {
            entityManager.createNativeQuery(
                            "UPDATE SUSCRIPCION SET activo = 0 " +
                                    "WHERE usuario_id = :userId AND activo = 1")
                    .setParameter("userId", usuarioId)
                    .executeUpdate();

            LocalDateTime fechaFin = LocalDateTime.now().plusDays(dias);
            entityManager.createNativeQuery(
                            "INSERT INTO SUSCRIPCION (suscripcion_id, usuario_id, plan, " +
                                    "fecha_inicio, fecha_fin, activo, recibo_store) " +
                                    "VALUES (NEXTVAL('seq_suscripcion_id'), :userId, :plan, " +
                                    "NOW(), :fechaFin, 1, :recibo)")
                    .setParameter("userId", usuarioId)
                    .setParameter("plan", request.getPlan())
                    .setParameter("fechaFin", fechaFin)
                    .setParameter("recibo", request.getReciboStore())
                    .executeUpdate();

            entityManager.createNativeQuery(
                            "UPDATE USUARIO SET rol = 'PREMIUM' WHERE usuario_id = :userId")
                    .setParameter("userId", usuarioId)
                    .executeUpdate();
        }

        return obtenerSuscripcion(usuarioId);
    }

    @Transactional
    public BoostResponse activarBoost(Long usuarioId) {

        if (!isUserPremium(usuarioId)) {
            throw new RuntimeException("Solo usuarios Premium pueden activar boost");
        }

        String plan = obtenerPlan(usuarioId);
        int limiteSemanal = plan.equals("PREMIUM_ANUAL") ? 2 : 1;

        List<Object> boostsSemana = entityManager.createNativeQuery(
                        "SELECT boost_id FROM BOOST_HISTORIAL " +
                                "WHERE usuario_id = :userId " +
                                "AND fecha_activacion >= DATE_TRUNC('week', NOW())")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (boostsSemana.size() >= limiteSemanal) {
            throw new RuntimeException("Has alcanzado el limite de boosts semanales");
        }

        List<Object> boostActivo = entityManager.createNativeQuery(
                        "SELECT boost_id FROM BOOST_HISTORIAL " +
                                "WHERE usuario_id = :userId AND activo = 1 " +
                                "AND fecha_fin > NOW()")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (!boostActivo.isEmpty()) {
            throw new RuntimeException("Ya tienes un boost activo");
        }

        entityManager.createNativeQuery(
                        "INSERT INTO BOOST_HISTORIAL (boost_id, usuario_id, fecha_fin, activo) " +
                                "VALUES (NEXTVAL('seq_boost_id'), :userId, " +
                                "NOW() + INTERVAL '30 minutes', 1)")
                .setParameter("userId", usuarioId)
                .executeUpdate();

        List<Object[]> boostCreado = entityManager.createNativeQuery(
                        "SELECT boost_id, fecha_activacion, fecha_fin FROM BOOST_HISTORIAL " +
                                "WHERE usuario_id = :userId ORDER BY boost_id DESC LIMIT 1")
                .setParameter("userId", usuarioId)
                .getResultList();

        Object[] row = boostCreado.get(0);
        return BoostResponse.builder()
                .boostId(((Number) row[0]).longValue())
                .fechaActivacion(((java.sql.Timestamp) row[1]).toLocalDateTime())
                .fechaFin(((java.sql.Timestamp) row[2]).toLocalDateTime())
                .activo(true)
                .mensaje("Boost activado por 30 minutos")
                .build();
    }

    public NotifConfigResponse obtenerConfigNotif(Long usuarioId) {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT notif_pref_id, notif_matches, notif_mensajes, " +
                                "notif_super_likes, notif_vistas_perfil, " +
                                "silencio_inicio, silencio_fin " +
                                "FROM NOTIF_PREFERENCIAS WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Configuracion de notificaciones no encontrada");
        }

        Object[] row = resultados.get(0);
        return NotifConfigResponse.builder()
                .notifPrefId(((Number) row[0]).longValue())
                .notifMatches(((Number) row[1]).intValue() == 1)
                .notifMensajes(((Number) row[2]).intValue() == 1)
                .notifSuperLikes(((Number) row[3]).intValue() == 1)
                .notifVistasPerfil(((Number) row[4]).intValue() == 1)
                .silencioInicio((String) row[5])
                .silencioFin((String) row[6])
                .build();
    }

    @Transactional
    public NotifConfigResponse actualizarConfigNotif(Long usuarioId,
                                                     NotifConfigRequest request) {
        StringBuilder sql = new StringBuilder("UPDATE NOTIF_PREFERENCIAS SET ");
        boolean first = true;

        if (request.getNotifMatches() != null) {
            sql.append("notif_matches = ").append(request.getNotifMatches() ? 1 : 0);
            first = false;
        }
        if (request.getNotifMensajes() != null) {
            if (!first) sql.append(", ");
            sql.append("notif_mensajes = ").append(request.getNotifMensajes() ? 1 : 0);
            first = false;
        }
        if (request.getNotifSuperLikes() != null) {
            if (!first) sql.append(", ");
            sql.append("notif_super_likes = ").append(request.getNotifSuperLikes() ? 1 : 0);
            first = false;
        }
        if (request.getNotifVistasPerfil() != null) {
            if (!first) sql.append(", ");
            sql.append("notif_vistas_perfil = ").append(request.getNotifVistasPerfil() ? 1 : 0);
            first = false;
        }
        if (request.getSilencioInicio() != null) {
            if (!first) sql.append(", ");
            sql.append("silencio_inicio = '").append(request.getSilencioInicio()).append("'");
            first = false;
        }
        if (request.getSilencioFin() != null) {
            if (!first) sql.append(", ");
            sql.append("silencio_fin = '").append(request.getSilencioFin()).append("'");
        }

        sql.append(" WHERE usuario_id = :userId");

        entityManager.createNativeQuery(sql.toString())
                .setParameter("userId", usuarioId)
                .executeUpdate();

        return obtenerConfigNotif(usuarioId);
    }

    public boolean isUserPremium(Long usuarioId) {
        List<Object> resultados = entityManager.createNativeQuery(
                        "SELECT suscripcion_id FROM SUSCRIPCION " +
                                "WHERE usuario_id = :userId AND activo = 1 " +
                                "AND plan != 'GRATUITO' AND fecha_fin > NOW()")
                .setParameter("userId", usuarioId)
                .getResultList();
        return !resultados.isEmpty();
    }

    private String obtenerPlan(Long usuarioId) {
        List<String> planes = entityManager.createNativeQuery(
                        "SELECT plan FROM SUSCRIPCION " +
                                "WHERE usuario_id = :userId AND activo = 1")
                .setParameter("userId", usuarioId)
                .getResultList();
        return planes.isEmpty() ? "GRATUITO" : planes.get(0);
    }

    @Transactional
    private void degradarAGratuito(Long usuarioId) {
        entityManager.createNativeQuery(
                        "UPDATE SUSCRIPCION SET activo = 0 " +
                                "WHERE usuario_id = :userId AND activo = 1")
                .setParameter("userId", usuarioId)
                .executeUpdate();

        entityManager.createNativeQuery(
                        "INSERT INTO SUSCRIPCION (suscripcion_id, usuario_id, plan, activo) " +
                                "VALUES (NEXTVAL('seq_suscripcion_id'), :userId, 'GRATUITO', 1)")
                .setParameter("userId", usuarioId)
                .executeUpdate();

        entityManager.createNativeQuery(
                        "UPDATE USUARIO SET rol = 'USER' WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .executeUpdate();
    }
}