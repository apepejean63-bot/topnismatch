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
        if (request.getProfesion() != null) perfil.setProfesion(request.getProfesion());
        if (request.getEducacion() != null) perfil.setEducacion(request.getEducacion());
        if (request.getIdioma() != null) perfil.setIdioma(request.getIdioma());
        if (request.getSignoZodiacal() != null) perfil.setSignoZodiacal(request.getSignoZodiacal());
        if (request.getMascotas() != null) perfil.setMascotas(request.getMascotas());
        if (request.getAlcohol() != null) perfil.setAlcohol(request.getAlcohol());
        if (request.getTabaco() != null) perfil.setTabaco(request.getTabaco());
        if (request.getEjercicio() != null) perfil.setEjercicio(request.getEjercicio());
        if (request.getTieneHijos() != null) perfil.setTieneHijos(request.getTieneHijos());
        if (request.getQuiereHijos() != null) perfil.setQuiereHijos(request.getQuiereHijos());
        if (request.getReligion() != null) perfil.setReligion(request.getReligion());
        if (request.getObjetivo() != null) perfil.setObjetivo(request.getObjetivo());
        if (request.getFechaNacimiento() != null) perfil.setFechaNacimiento(request.getFechaNacimiento());
        if (request.getFotoPrincipalUrl() != null) {
            List<Foto> fotosExistentes = entityManager.createQuery("SELECT f FROM Foto f WHERE f.usuarioId = :userId AND f.orden = 1", Foto.class).setParameter("userId", usuarioId).getResultList();
            if (!fotosExistentes.isEmpty()) {
                fotosExistentes.get(0).setUrl(request.getFotoPrincipalUrl());
                entityManager.merge(fotosExistentes.get(0));
                perfil.setFotoPrincipalId(fotosExistentes.get(0).getFotoId());
            } else {
                Foto foto = Foto.builder().usuarioId(usuarioId).url(request.getFotoPrincipalUrl()).orden(1).build();
                entityManager.persist(foto);
                entityManager.flush();
                perfil.setFotoPrincipalId(foto.getFotoId());
            }
        }
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

        Long count = entityManager.createQuery(
                        "SELECT COUNT(f) FROM Foto f WHERE f.usuarioId = :userId",
                        Long.class)
                .setParameter("userId", usuarioId)
                .getSingleResult();

        if (count >= 6) {
            throw new RuntimeException("Maximo 6 fotos permitidas");
        }

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

        if (request.getOrden() == 1) {
            entityManager.createNativeQuery(
                            "UPDATE perfil SET foto_principal_id = :fotoId WHERE usuario_id = :userId")
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

        if (orden == 1) {
            entityManager.createNativeQuery(
                            "UPDATE perfil SET foto_principal_id = NULL WHERE usuario_id = :userId")
                    .setParameter("userId", usuarioId)
                    .executeUpdate();
        }

        try {
            entityManager.remove(entityManager.contains(foto) ? foto : entityManager.merge(foto));
        } catch (Exception e) {
            throw new RuntimeException("Error al eliminar foto: " + e.getMessage() + " causa: " + e.getCause());
        }
    }

    private ProfileResponse buildProfileResponse(Perfil perfil, Long usuarioId) {

        List<String> nombres = entityManager.createQuery(
                        "SELECT u.nombre FROM Usuario u WHERE u.usuarioId = :userId",
                        String.class)
                .setParameter("userId", usuarioId)
                .getResultList();

        String nombre = nombres.isEmpty() ? "" : nombres.get(0);

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
                .profesion(perfil.getProfesion())
                .educacion(perfil.getEducacion())
                .idioma(perfil.getIdioma())
                .signoZodiacal(perfil.getSignoZodiacal())
                .mascotas(perfil.getMascotas())
                .alcohol(perfil.getAlcohol())
                .tabaco(perfil.getTabaco())
                .ejercicio(perfil.getEjercicio())
                .tieneHijos(perfil.getTieneHijos())
                .quiereHijos(perfil.getQuiereHijos())
                .religion(perfil.getReligion())
                .fechaNacimiento(perfil.getFechaNacimiento())
                .fotoPrincipalUrl(perfil.getFotoPrincipalId() != null ? entityManager.createQuery("SELECT f.url FROM Foto f WHERE f.fotoId = :fotoId", String.class).setParameter("fotoId", perfil.getFotoPrincipalId()).getSingleResult() : null)
                .build();
    }
}


