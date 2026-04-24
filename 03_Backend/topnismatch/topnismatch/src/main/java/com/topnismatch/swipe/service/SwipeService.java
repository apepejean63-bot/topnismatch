package com.topnismatch.swipe.service;

import com.topnismatch.swipe.dto.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SwipeService {

    @PersistenceContext
    private EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public List<DiscoverResponse> discover(Long usuarioId) {

        // Obtener preferencias del usuario
        List<Object[]> prefList = entityManager.createNativeQuery(
                        "SELECT p.edad_min_buscada, p.edad_max_buscada, p.genero_buscado, " +
                                "p.distancia_max_km FROM PERFIL p WHERE p.usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getResultList();

        Integer edadMin = 18;
        Integer edadMax = 99;
        String generoBuscado = null;

        if (!prefList.isEmpty()) {
            Object[] pref = prefList.get(0);
            edadMin = pref[0] != null ? ((Number) pref[0]).intValue() : 18;
            edadMax = pref[1] != null ? ((Number) pref[1]).intValue() : 99;
            generoBuscado = pref[2] != null ? (String) pref[2] : null;
        }

        // Query para descubrir perfiles
        // Excluir: yo mismo, ya swiped, bloqueados, sin perfil
        String sql =
                "SELECT u.usuario_id, u.nombre, u.fecha_nacimiento, u.genero, " +
                        "p.perfil_id, p.bio, p.ciudad, p.intereses, p.foto_principal_id " +
                        "FROM USUARIO u " +
                        "JOIN PERFIL p ON u.usuario_id = p.usuario_id " +
                        "WHERE u.usuario_id != :userId " +
                        "AND u.activo = 1 " +
                        "AND u.usuario_id NOT IN (" +
                        "   SELECT la.usuario_destino FROM LIKE_ACCION la " +
                        "   WHERE la.usuario_origen = :userId" +
                        ") " +
                        "AND u.usuario_id NOT IN (" +
                        "   SELECT b.usuario_bloqueado FROM BLOQUEO b " +
                        "   WHERE b.usuario_bloqueador = :userId" +
                        ") " +
                        "AND TRUNC(MONTHS_BETWEEN(SYSDATE, u.fecha_nacimiento)/12) BETWEEN :edadMin AND :edadMax " +
                        "FETCH FIRST 20 ROWS ONLY";

        List<Object[]> resultados = entityManager.createNativeQuery(sql)
                .setParameter("userId", usuarioId)
                .setParameter("edadMin", edadMin)
                .setParameter("edadMax", edadMax)
                .getResultList();

        List<DiscoverResponse> perfiles = new ArrayList<>();

        for (Object[] row : resultados) {
            Long uid = ((Number) row[0]).longValue();
            String nombre = (String) row[1];
            java.util.Date fechaNac = (java.util.Date) row[2];
            int edad = calcularEdad(fechaNac);
            Long perfilId = ((Number) row[4]).longValue();
            String bio = (String) row[5];
            String ciudad = (String) row[6];
            String intereses = (String) row[7];
            Long fotoPrincipalId = row[8] != null ? ((Number) row[8]).longValue() : null;

            // Obtener URL foto principal
            String fotoPrincipalUrl = null;
            if (fotoPrincipalId != null) {
                List<String> urls = entityManager.createNativeQuery(
                                "SELECT url FROM FOTO WHERE foto_id = :fotoId")
                        .setParameter("fotoId", fotoPrincipalId)
                        .getResultList();
                fotoPrincipalUrl = urls.isEmpty() ? null : urls.get(0);
            }

            // Obtener todas las fotos
            List<String> fotosUrls = entityManager.createNativeQuery(
                            "SELECT url FROM FOTO WHERE usuario_id = :uid ORDER BY orden")
                    .setParameter("uid", uid)
                    .getResultList();

            // Filtrar por género si está definido
            if (generoBuscado != null) {
                String generoUsuario = (String) row[3];
                if (!generoBuscado.equals(generoUsuario)) {
                    continue;
                }
            }

            perfiles.add(DiscoverResponse.builder()
                    .usuarioId(uid)
                    .perfilId(perfilId)
                    .nombre(nombre)
                    .edad(edad)
                    .bio(bio)
                    .ciudad(ciudad)
                    .intereses(intereses)
                    .fotoPrincipalUrl(fotoPrincipalUrl)
                    .fotosUrls(fotosUrls)
                    .build());
        }

        return perfiles;
    }

    @Transactional
    public SwipeResponse darLike(Long usuarioOrigen, Long usuarioDestino) {
        return procesarSwipe(usuarioOrigen, usuarioDestino, "LIKE");
    }

    @Transactional
    public SwipeResponse darDislike(Long usuarioOrigen, Long usuarioDestino) {
        return procesarSwipe(usuarioOrigen, usuarioDestino, "DISLIKE");
    }

    @Transactional
    public SwipeResponse darSuperlike(Long usuarioOrigen, Long usuarioDestino) {
        return procesarSwipe(usuarioOrigen, usuarioDestino, "SUPERLIKE");
    }

    private SwipeResponse procesarSwipe(Long origen, Long destino, String tipo) {

        // Verificar que no exista ya una acción
        List<Object> existente = entityManager.createNativeQuery(
                        "SELECT like_id FROM LIKE_ACCION " +
                                "WHERE usuario_origen = :origen AND usuario_destino = :destino")
                .setParameter("origen", origen)
                .setParameter("destino", destino)
                .getResultList();

        if (!existente.isEmpty()) {
            throw new RuntimeException("Ya realizaste una accion sobre este usuario");
        }

        // Guardar la acción
        entityManager.createNativeQuery(
                        "INSERT INTO LIKE_ACCION (like_id, usuario_origen, usuario_destino, tipo) " +
                                "VALUES (SEQ_LIKE_ID.NEXTVAL, :origen, :destino, :tipo)")
                .setParameter("origen", origen)
                .setParameter("destino", destino)
                .setParameter("tipo", tipo)
                .executeUpdate();

        // Si es LIKE o SUPERLIKE verificar match mutuo
        if (tipo.equals("LIKE") || tipo.equals("SUPERLIKE")) {
            List<Object[]> likeRecíproco = entityManager.createNativeQuery(
                            "SELECT like_id FROM LIKE_ACCION " +
                                    "WHERE usuario_origen = :destino AND usuario_destino = :origen " +
                                    "AND tipo IN ('LIKE', 'SUPERLIKE')")
                    .setParameter("origen", origen)
                    .setParameter("destino", destino)
                    .getResultList();

            if (!likeRecíproco.isEmpty()) {
                // Calcular compatibilidad
                double compatibilidad = calcularCompatibilidad(origen, destino);

                // Crear match
                entityManager.createNativeQuery(
                                "INSERT INTO MATCH_TOPNIS (match_id, usuario1_id, usuario2_id, compatibilidad) " +
                                        "VALUES (SEQ_MATCH_ID.NEXTVAL, :u1, :u2, :compat)")
                        .setParameter("u1", Math.min(origen, destino))
                        .setParameter("u2", Math.max(origen, destino))
                        .setParameter("compat", compatibilidad)
                        .executeUpdate();

                // Obtener el match creado
                List<Object> matchCreado = entityManager.createNativeQuery(
                                "SELECT match_id FROM MATCH_TOPNIS " +
                                        "WHERE usuario1_id = :u1 AND usuario2_id = :u2")
                        .setParameter("u1", Math.min(origen, destino))
                        .setParameter("u2", Math.max(origen, destino))
                        .getResultList();

                Long matchId = matchCreado.isEmpty() ? null :
                        ((Number) matchCreado.get(0)).longValue();

                return SwipeResponse.conMatch(matchId);
            }
        }

        return SwipeResponse.sinMatch(tipo);
    }

    private double calcularCompatibilidad(Long usuario1, Long usuario2) {
        // Obtener intereses de ambos usuarios
        List<String> intereses1 = entityManager.createNativeQuery(
                        "SELECT intereses FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuario1)
                .getResultList();

        List<String> intereses2 = entityManager.createNativeQuery(
                        "SELECT intereses FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuario2)
                .getResultList();

        if (intereses1.isEmpty() || intereses2.isEmpty()) return 50.0;

        String i1 = intereses1.get(0);
        String i2 = intereses2.get(0);

        if (i1 == null || i2 == null) return 50.0;

        String[] arr1 = i1.split(",");
        String[] arr2 = i2.split(",");

        int comunes = 0;
        for (String a : arr1) {
            for (String b : arr2) {
                if (a.trim().equalsIgnoreCase(b.trim())) comunes++;
            }
        }

        int total = arr1.length + arr2.length;
        if (total == 0) return 50.0;

        double compatibilidad = (double) comunes * 2 / total * 100;
        return Math.min(100.0, Math.max(0.0, compatibilidad));
    }

    private int calcularEdad(java.util.Date fechaNacimiento) {
        if (fechaNacimiento == null) return 0;
        java.time.LocalDate hoy = java.time.LocalDate.now();
        java.time.LocalDate nacimiento = new java.sql.Date(fechaNacimiento.getTime()).toLocalDate();
        return java.time.Period.between(nacimiento, hoy).getYears();

    }
}