package com.topnismatch.admin.service;

import com.topnismatch.admin.dto.*;
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
public class AdminService {

    @PersistenceContext
    private EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public DashboardResponse obtenerDashboard() {

        Long usuariosTotales = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM USUARIO").getSingleResult()).longValue();

        Long usuariosActivos = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM USUARIO WHERE activo = 1").getSingleResult()).longValue();

        Long usuariosHoy = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM USUARIO WHERE TRUNC(fecha_registro) = TRUNC(SYSDATE)")
                .getSingleResult()).longValue();

        Long matchesTotales = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM MATCH_TOPNIS").getSingleResult()).longValue();

        Long matchesHoy = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM MATCH_TOPNIS WHERE TRUNC(fecha_match) = TRUNC(SYSDATE)")
                .getSingleResult()).longValue();

        Long mensajesTotales = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM MENSAJE").getSingleResult()).longValue();

        Long suscripcionesPremium = ((Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM SUSCRIPCION WHERE plan != 'GRATUITO' AND activo = 1 " +
                        "AND fecha_fin > SYSTIMESTAMP").getSingleResult()).longValue();

        Long reportesPendientes = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM REPORTE WHERE estado = 'PENDIENTE'")
                .getSingleResult()).longValue();

        return DashboardResponse.builder()
                .usuariosTotales(usuariosTotales)
                .usuariosActivos(usuariosActivos)
                .usuariosHoy(usuariosHoy)
                .matchesTotales(matchesTotales)
                .matchesHoy(matchesHoy)
                .mensajesTotales(mensajesTotales)
                .suscripcionesPremium(suscripcionesPremium)
                .reportesPendientes(reportesPendientes)
                .build();
    }

    @SuppressWarnings("unchecked")
    public List<AdminUserResponse> listarUsuarios() {

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT u.usuario_id, u.nombre, u.email, u.rol, u.activo, " +
                                "u.email_verificado, u.fecha_registro, " +
                                "NVL((SELECT s.plan FROM SUSCRIPCION s WHERE s.usuario_id = u.usuario_id " +
                                "AND s.activo = 1), 'GRATUITO') as plan " +
                                "FROM USUARIO u ORDER BY u.fecha_registro DESC")
                .getResultList();

        List<AdminUserResponse> usuarios = new ArrayList<>();

        for (Object[] row : resultados) {
            usuarios.add(AdminUserResponse.builder()
                    .usuarioId(((Number) row[0]).longValue())
                    .nombre((String) row[1])
                    .email((String) row[2])
                    .rol((String) row[3])
                    .activo(((Number) row[4]).intValue() == 1)
                    .emailVerificado(((Number) row[5]).intValue() == 1)
                    .fechaRegistro(((java.sql.Timestamp) row[6]).toLocalDateTime())
                    .plan((String) row[7])
                    .build());
        }

        return usuarios;
    }

    @Transactional
    public AdminUserResponse cambiarEstadoUsuario(Long usuarioId, Boolean activo) {

        entityManager.createNativeQuery(
                        "UPDATE USUARIO SET activo = :activo WHERE usuario_id = :userId")
                .setParameter("activo", activo ? 1 : 0)
                .setParameter("userId", usuarioId)
                .executeUpdate();

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT u.usuario_id, u.nombre, u.email, u.rol, u.activo, " +
                                "u.email_verificado, u.fecha_registro, " +
                                "NVL((SELECT s.plan FROM SUSCRIPCION s WHERE s.usuario_id = u.usuario_id " +
                                "AND s.activo = 1), 'GRATUITO') as plan " +
                                "FROM USUARIO u WHERE u.usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();

        if (resultados.isEmpty()) {
            throw new RuntimeException("Usuario no encontrado");
        }

        Object[] row = resultados.get(0);
        return AdminUserResponse.builder()
                .usuarioId(((Number) row[0]).longValue())
                .nombre((String) row[1])
                .email((String) row[2])
                .rol((String) row[3])
                .activo(((Number) row[4]).intValue() == 1)
                .emailVerificado(((Number) row[5]).intValue() == 1)
                .fechaRegistro(((java.sql.Timestamp) row[6]).toLocalDateTime())
                .plan((String) row[7])
                .build();
    }

    @SuppressWarnings("unchecked")
    public List<AdminReportResponse> listarReportes(String estado) {

        String sql = "SELECT r.reporte_id, r.usuario_denunciante, u1.nombre, " +
                "r.usuario_denunciado, u2.nombre, r.categoria, r.descripcion, " +
                "r.estado, r.nota_admin, r.fecha_reporte, r.fecha_resolucion " +
                "FROM REPORTE r " +
                "JOIN USUARIO u1 ON r.usuario_denunciante = u1.usuario_id " +
                "JOIN USUARIO u2 ON r.usuario_denunciado = u2.usuario_id ";

        if (estado != null && !estado.isEmpty()) {
            sql += "WHERE r.estado = '" + estado + "' ";
        }

        sql += "ORDER BY r.fecha_reporte DESC";

        List<Object[]> resultados = entityManager.createNativeQuery(sql).getResultList();
        List<AdminReportResponse> reportes = new ArrayList<>();

        for (Object[] row : resultados) {
            LocalDateTime fechaResolucion = row[10] != null ?
                    ((java.sql.Timestamp) row[10]).toLocalDateTime() : null;

            reportes.add(AdminReportResponse.builder()
                    .reporteId(((Number) row[0]).longValue())
                    .usuarioDenuncianteId(((Number) row[1]).longValue())
                    .nombreDenunciante((String) row[2])
                    .usuarioDenunciadoId(((Number) row[3]).longValue())
                    .nombreDenunciado((String) row[4])
                    .categoria((String) row[5])
                    .descripcion((String) row[6])
                    .estado((String) row[7])
                    .notaAdmin((String) row[8])
                    .fechaReporte(((java.sql.Timestamp) row[9]).toLocalDateTime())
                    .fechaResolucion(fechaResolucion)
                    .build());
        }

        return reportes;
    }

    @Transactional
    public AdminReportResponse resolverReporte(Long reporteId, Long adminId,
                                               ResolveReportRequest request) {

        entityManager.createNativeQuery(
                        "UPDATE REPORTE SET estado = :estado, nota_admin = :nota, " +
                                "admin_resolutor_id = :adminId " +
                                "WHERE reporte_id = :reporteId")
                .setParameter("estado", request.getEstado())
                .setParameter("nota", request.getNotaAdmin())
                .setParameter("adminId", adminId)
                .setParameter("reporteId", reporteId)
                .executeUpdate();

        if (Boolean.TRUE.equals(request.getBloquearUsuario())) {
            List<Object[]> reporte = entityManager.createNativeQuery(
                            "SELECT usuario_denunciado FROM REPORTE WHERE reporte_id = :id")
                    .setParameter("id", reporteId)
                    .getResultList();

            if (!reporte.isEmpty()) {
                Long usuarioBloqueado = ((Number) ((Object[]) reporte.get(0))[0]).longValue();
                entityManager.createNativeQuery(
                                "UPDATE USUARIO SET activo = 0 WHERE usuario_id = :userId")
                        .setParameter("userId", usuarioBloqueado)
                        .executeUpdate();
            }
        }

        List<Object[]> resultados = entityManager.createNativeQuery(
                        "SELECT r.reporte_id, r.usuario_denunciante, u1.nombre, " +
                                "r.usuario_denunciado, u2.nombre, r.categoria, r.descripcion, " +
                                "r.estado, r.nota_admin, r.fecha_reporte, r.fecha_resolucion " +
                                "FROM REPORTE r " +
                                "JOIN USUARIO u1 ON r.usuario_denunciante = u1.usuario_id " +
                                "JOIN USUARIO u2 ON r.usuario_denunciado = u2.usuario_id " +
                                "WHERE r.reporte_id = :reporteId")
                .setParameter("reporteId", reporteId)
                .getResultList();

        Object[] row = resultados.get(0);
        LocalDateTime fechaResolucion = row[10] != null ?
                ((java.sql.Timestamp) row[10]).toLocalDateTime() : null;

        return AdminReportResponse.builder()
                .reporteId(((Number) row[0]).longValue())
                .usuarioDenuncianteId(((Number) row[1]).longValue())
                .nombreDenunciante((String) row[2])
                .usuarioDenunciadoId(((Number) row[3]).longValue())
                .nombreDenunciado((String) row[4])
                .categoria((String) row[5])
                .descripcion((String) row[6])
                .estado((String) row[7])
                .notaAdmin((String) row[8])
                .fechaReporte(((java.sql.Timestamp) row[9]).toLocalDateTime())
                .fechaResolucion(fechaResolucion)
                .build();
    }
}