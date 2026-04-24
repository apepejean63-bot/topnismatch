package com.topnismatch.profile.service;

import com.topnismatch.profile.dto.*;
import com.topnismatch.profile.entity.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProfileService {

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional
    public ProfileResponse crearPerfil(Long usuarioId, ProfileRequest request) {

        // Verificar que no exista ya un perfil
        Long count = entityManager.createQuery(
                        "SELECT COUNT(p) FROM Perfil p WHERE p.usuarioId = :userId",
                        Long.class)
                .setParameter("userId", usuarioId)
                .getSingleResult();

        if (count > 0) {
            throw new RuntimeException("El usuario ya tiene un perfil creado");
        }

        Perfil perfil = Perfil.builder()
                .usuarioId(usuarioId)
                .bio(request.getBio())
                .ciudad(request.getCiudad())
                .objetivo("RELACION_SERIA")
                .intereses(request.getIntereses())
                .edadMinBuscada(request.getEdadMinBuscada() != null ? request.getEdadMinBuscada() : 18)
                .edadMaxBuscada(request.getEdadMaxBuscada() != null ? request.getEdadMaxBuscada() : 99)
                .distanciaMaxKm(request.getDistanciaMaxKm() != null ? request.getDistanciaMaxKm() : 50)
                .generoBuscado(request.getGeneroBuscado())
                .build();

        entityManager.persist(perfil);
        entityManager.flush();

        return buildProfileResponse(perfil, usuarioId);
    }

    @Transactional
    public ProfileResponse editarPerfil(Long usuarioId, ProfileRequest request) {

        List<Perfil> perfiles = entityManager.createQuery(
                        "SELECT p FROM Perfil p WHERE p.usuarioId = :userId",
                        Perfil.class)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (perfiles.isEmpty()) {
            throw new RuntimeException("Perfil no encontrado");
        }

        Perfil perfil = perfiles.get(0);

        if (request.getBio() != null) perfil.setBio(request.getBio());
        if (request.getCiudad() != null) perfil.setCiudad(request.getCiudad());
        if (request.getIntereses() != null) perfil.setIntereses(request.getIntereses());
        if (request.getEdadMinBuscada() != null) perfil.setEdadMinBuscada(request.getEdadMinBuscada());
        if (request.getEdadMaxBuscada() != null) perfil.setEdadMaxBuscada(request.getEdadMaxBuscada());
        if (request.getDistanciaMaxKm() != null) perfil.setDistanciaMaxKm(request.getDistanciaMaxKm());
        if (request.getGeneroBuscado() != null) perfil.setGeneroBuscado(request.getGeneroBuscado());

        entityManager.merge(perfil);

        return buildProfileResponse(perfil, usuarioId);
    }

    public ProfileResponse obtenerMiPerfil(Long usuarioId) {

        List<Perfil> perfiles = entityManager.createQuery(
                        "SELECT p FROM Perfil p WHERE p.usuarioId = :userId",
                        Perfil.class)
                .setParameter("userId", usuarioId)
                .getResultList();

        if (perfiles.isEmpty()) {
            throw new RuntimeException("Perfil no encontrado");
        }

        return buildProfileResponse(perfiles.get(0), usuarioId);
    }

    public ProfileResponse obtenerPerfilPorId(Long perfilId) {

        List<Perfil> perfiles = entityManager.createQuery(
                        "SELECT p FROM Perfil p WHERE p.perfilId = :perfilId",
                        Perfil.class)
                .setParameter("perfilId", perfilId)
                .getResultList();

        if (perfiles.isEmpty()) {
            throw new RuntimeException("Perfil no encontrado");
        }

        Perfil perfil = perfiles.get(0);
        return buildProfileResponse(perfil, perfil.getUsuarioId());
    }

    @Transactional
    public FotoResponse agregarFoto(Long usuarioId, FotoRequest request) {

        // Verificar max 6 fotos
        Long count = entityManager.createQuery(
                        "SELECT COUNT(f) FROM Foto f WHERE f.usuarioId = :userId",
                        Long.class)
                .setParameter("userId", usuarioId)
                .getSingleResult();

        if (count >= 6) {
            throw new RuntimeException("Maximo 6 fotos permitidas");
        }

        // Verificar que el orden no esté ocupado
        List<Foto> fotosConOrden = entityManager.createQuery(
                        "SELECT f FROM Foto f WHERE f.usuarioId = :userId AND f.orden = :orden",
                        Foto.class)
                .setParameter("userId", usuarioId)
                .setParameter("orden", request.getOrden())
                .getResultList();

        if (!fotosConOrden.isEmpty()) {
            throw new RuntimeException("Ya existe una foto en la posicion " + request.getOrden());
        }

        Foto foto = Foto.builder()
                .usuarioId(usuarioId)
                .url(request.getUrl())
                .orden(request.getOrden())
                .build();

        entityManager.persist(foto);
        entityManager.flush();

        // Si es orden 1 actualizar foto_principal_id en perfil
        if (request.getOrden() == 1) {
            entityManager.createNativeQuery(
                            "UPDATE PERFIL SET foto_principal_id = :fotoId WHERE usuario_id = :userId")
                    .setParameter("fotoId", foto.getFotoId())
                    .setParameter("userId", usuarioId)
                    .executeUpdate();
        }

        return FotoResponse.builder()
                .fotoId(foto.getFotoId())
                .url(foto.getUrl())
                .orden(foto.getOrden())
                .build();
    }

    @Transactional
    public void eliminarFoto(Long usuarioId, Integer orden) {

        List<Foto> fotos = entityManager.createQuery(
                        "SELECT f FROM Foto f WHERE f.usuarioId = :userId AND f.orden = :orden",
                        Foto.class)
                .setParameter("userId", usuarioId)
                .setParameter("orden", orden)
                .getResultList();

        if (fotos.isEmpty()) {
            throw new RuntimeException("Foto no encontrada en la posicion " + orden);
        }

        Foto foto = fotos.get(0);

        // Si es foto principal limpiar referencia en perfil
        if (orden == 1) {
            entityManager.createNativeQuery(
                            "UPDATE PERFIL SET foto_principal_id = NULL WHERE usuario_id = :userId")
                    .setParameter("userId", usuarioId)
                    .executeUpdate();
        }

        entityManager.remove(entityManager.contains(foto) ? foto : entityManager.merge(foto));
    }

    private ProfileResponse buildProfileResponse(Perfil perfil, Long usuarioId) {

        // Obtener nombre del usuario
        List<String> nombres = entityManager.createQuery(
                        "SELECT u.nombre FROM Usuario u WHERE u.usuarioId = :userId",
                        String.class)
                .setParameter("userId", usuarioId)
                .getResultList();

        String nombre = nombres.isEmpty() ? "" : nombres.get(0);

        // Obtener fotos
        List<Foto> fotos = entityManager.createQuery(
                        "SELECT f FROM Foto f WHERE f.usuarioId = :userId ORDER BY f.orden",
                        Foto.class)
                .setParameter("userId", usuarioId)
                .getResultList();

        List<FotoResponse> fotosResponse = fotos.stream()
                .map(f -> FotoResponse.builder()
                        .fotoId(f.getFotoId())
                        .url(f.getUrl())
                        .orden(f.getOrden())
                        .build())
                .collect(Collectors.toList());

        return ProfileResponse.builder()
                .perfilId(perfil.getPerfilId())
                .usuarioId(perfil.getUsuarioId())
                .nombre(nombre)
                .bio(perfil.getBio())
                .ciudad(perfil.getCiudad())
                .objetivo(perfil.getObjetivo())
                .intereses(perfil.getIntereses())
                .edadMinBuscada(perfil.getEdadMinBuscada())
                .edadMaxBuscada(perfil.getEdadMaxBuscada())
                .distanciaMaxKm(perfil.getDistanciaMaxKm())
                .generoBuscado(perfil.getGeneroBuscado())
                .fotoPrincipalId(perfil.getFotoPrincipalId())
                .fotos(fotosResponse)
                .build();
    }
}