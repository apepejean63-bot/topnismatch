package com.topnismatch.profile.service;

import com.topnismatch.auth.dto.AuthResponse;
import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.service.AuthService;
import com.topnismatch.profile.dto.ProfileRequest;
import com.topnismatch.profile.dto.FotoRequest;
import com.topnismatch.profile.dto.FotoResponse;
import com.topnismatch.profile.dto.ProfileResponse;
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

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@Transactional
class ProfileServiceIntegrationTest {

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
    private ProfileService profileService;

    @Autowired
    private AuthService authService;

    @Autowired
    private EntityManager entityManager;

    private Long crearUsuarioRegistrado(String email) {
        RegisterRequest request = RegisterRequest.builder()
                .nombre("Profile Test")
                .email(email)
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        AuthResponse respuesta = authService.register(request);
        return respuesta.getUsuarioId();
    }

    @Test
    void crearPerfilDeberiaGuardarloConValoresCorrectos() {
        Long usuarioId = crearUsuarioRegistrado("profiletest@integracion.com");

        ProfileRequest request = ProfileRequest.builder()
                .bio("Me gusta viajar y leer")
                .ciudad("Santiago")
                .intereses("viajes,lectura,musica")
                .build();

        ProfileResponse respuesta = profileService.crearPerfil(usuarioId, request);

        assertNotNull(respuesta.getPerfilId());
        assertEquals(usuarioId, respuesta.getUsuarioId());
        assertEquals("Profile Test", respuesta.getNombre());
        assertEquals("Me gusta viajar y leer", respuesta.getBio());
        assertEquals("Santiago", respuesta.getCiudad());
        assertEquals("viajes,lectura,musica", respuesta.getIntereses());
        assertEquals("RELACION_SERIA", respuesta.getObjetivo());
        assertEquals(18, respuesta.getEdadMinBuscada());
        assertEquals(99, respuesta.getEdadMaxBuscada());
        assertEquals(50, respuesta.getDistanciaMaxKm());
    }
    @Test
    void crearPerfilDeberiaRechazarSegundoIntento() {
        Long usuarioId = crearUsuarioRegistrado("profiledup@integracion.com");

        ProfileRequest request1 = ProfileRequest.builder()
                .bio("Primer perfil")
                .ciudad("Santiago")
                .build();
        profileService.crearPerfil(usuarioId, request1);

        ProfileRequest request2 = ProfileRequest.builder()
                .bio("Segundo intento")
                .ciudad("Valparaiso")
                .build();

        assertThrows(RuntimeException.class, () -> {
            profileService.crearPerfil(usuarioId, request2);
        }, "No deberia permitirse crear un segundo perfil para el mismo usuario");

        Long cantidadPerfiles = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadPerfiles, "Deberia seguir existiendo solamente 1 perfil para ese usuario");
    }
    @Test
    void editarPerfilDeberiaActualizarCamposCorrectamente() {
        Long usuarioId = crearUsuarioRegistrado("profileedit@integracion.com");

        ProfileRequest requestInicial = ProfileRequest.builder()
                .bio("Bio original")
                .ciudad("Santiago")
                .intereses("lectura")
                .build();
        ProfileResponse perfilCreado = profileService.crearPerfil(usuarioId, requestInicial);

        ProfileRequest requestEdicion = ProfileRequest.builder()
                .bio("Bio actualizada")
                .ciudad("Valparaiso")
                .intereses("viajes,musica")
                .profesion("Ingeniero")
                .build();
        profileService.editarPerfil(usuarioId, requestEdicion);

        ProfileResponse perfilActualizado = profileService.obtenerMiPerfil(usuarioId);

        assertEquals(perfilCreado.getPerfilId(), perfilActualizado.getPerfilId(),
                "Deberia seguir siendo el mismo perfil, no uno nuevo");
        assertEquals(usuarioId, perfilActualizado.getUsuarioId());
        assertEquals("Bio actualizada", perfilActualizado.getBio());
        assertEquals("Valparaiso", perfilActualizado.getCiudad());
        assertEquals("viajes,musica", perfilActualizado.getIntereses());
        assertEquals("Ingeniero", perfilActualizado.getProfesion());

        Long cantidadPerfiles = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadPerfiles, "No deberia haberse creado un segundo perfil al editar");
    }
    @Test
    void editarPerfilDeberiaRechazarBioConContenidoProhibido() {
        Long usuarioId = crearUsuarioRegistrado("profilebioprohibida@integracion.com");

        ProfileRequest requestInicial = ProfileRequest.builder()
                .bio("Bio original valida")
                .ciudad("Santiago")
                .build();
        profileService.crearPerfil(usuarioId, requestInicial);

        ProfileRequest requestConBioProhibida = ProfileRequest.builder()
                .bio("Escribeme por WhatsApp para conocernos mejor")
                .build();

        assertThrows(RuntimeException.class, () -> {
            profileService.editarPerfil(usuarioId, requestConBioProhibida);
        }, "Deberia rechazar una bio que contiene contenido prohibido");

        ProfileResponse perfilSinCambios = profileService.obtenerMiPerfil(usuarioId);
        assertEquals("Bio original valida", perfilSinCambios.getBio(),
                "La bio anterior deberia permanecer intacta tras el intento rechazado");
    }
    @Test
    void agregarFotoDeberiaGuardarlaYVincularComoPrincipal() {
        Long usuarioId = crearUsuarioRegistrado("profilefoto@integracion.com");

        ProfileRequest requestPerfil = ProfileRequest.builder()
                .bio("Perfil con foto")
                .build();
        profileService.crearPerfil(usuarioId, requestPerfil);

        FotoRequest fotoRequest = new FotoRequest();
        fotoRequest.setUrl("https://storage.example.com/foto1.jpg");
        fotoRequest.setOrden(1);

        FotoResponse respuestaFoto = profileService.agregarFoto(usuarioId, fotoRequest);

        assertNotNull(respuestaFoto.getFotoId());
        assertEquals("https://storage.example.com/foto1.jpg", respuestaFoto.getUrl());
        assertEquals(1, respuestaFoto.getOrden());

        Long usuarioEnBD = ((Number) entityManager.createNativeQuery(
                        "SELECT usuario_id FROM FOTO WHERE foto_id = :fotoId")
                .setParameter("fotoId", respuestaFoto.getFotoId())
                .getSingleResult()).longValue();
        assertEquals(usuarioId.longValue(), usuarioEnBD, "La foto deberia pertenecer al usuario correcto");

        Long fotoPrincipalEnPerfil = ((Number) entityManager.createNativeQuery(
                        "SELECT foto_principal_id FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(respuestaFoto.getFotoId(), fotoPrincipalEnPerfil,
                "La foto de orden 1 deberia quedar vinculada como foto principal del perfil");
    }
    @Test
    void agregarFotoDeberiaRechazarLaSeptimaFoto() {
        Long usuarioId = crearUsuarioRegistrado("profilefotolimite@integracion.com");

        ProfileRequest requestPerfil = ProfileRequest.builder()
                .bio("Perfil con varias fotos")
                .build();
        profileService.crearPerfil(usuarioId, requestPerfil);

        for (int i = 1; i <= 6; i++) {
            FotoRequest fotoRequest = new FotoRequest();
            fotoRequest.setUrl("https://storage.example.com/foto" + i + ".jpg");
            fotoRequest.setOrden(i);
            profileService.agregarFoto(usuarioId, fotoRequest);
        }

        Long cantidadAntesDelIntento = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM FOTO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(6L, cantidadAntesDelIntento, "Deberian existir exactamente 6 fotos antes del septimo intento");

        FotoRequest septimaFoto = new FotoRequest();
        septimaFoto.setUrl("https://storage.example.com/foto7.jpg");
        septimaFoto.setOrden(6);

        assertThrows(RuntimeException.class, () -> {
            profileService.agregarFoto(usuarioId, septimaFoto);
        }, "No deberia permitirse agregar una septima foto");

        Long cantidadDespuesDelIntento = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM FOTO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(6L, cantidadDespuesDelIntento, "Deberian seguir existiendo exactamente 6 fotos, la septima no debio insertarse");
    }
    @Test
    void eliminarFotoDeberiaBorrarlaYLimpiarFotoPrincipal() {
        Long usuarioId = crearUsuarioRegistrado("profileeliminarfoto@integracion.com");

        ProfileRequest requestPerfil = ProfileRequest.builder()
                .bio("Perfil para eliminar foto")
                .build();
        profileService.crearPerfil(usuarioId, requestPerfil);

        FotoRequest fotoRequest = new FotoRequest();
        fotoRequest.setUrl("https://storage.example.com/foto-a-borrar.jpg");
        fotoRequest.setOrden(1);
        FotoResponse fotoCreada = profileService.agregarFoto(usuarioId, fotoRequest);

        Long cantidadAntes = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM FOTO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadAntes, "Deberia existir 1 foto antes de eliminar");

        profileService.eliminarFoto(usuarioId, 1);

        Long cantidadDespues = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM FOTO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(0L, cantidadDespues, "La foto deberia haberse eliminado");

        Object fotoPrincipalEnPerfil = entityManager.createNativeQuery(
                        "SELECT foto_principal_id FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult();
        assertNull(fotoPrincipalEnPerfil, "El perfil no deberia seguir apuntando a la foto eliminada");

        Long cantidadPerfiles = ((Number) entityManager.createNativeQuery(
                        "SELECT COUNT(*) FROM PERFIL WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult()).longValue();
        assertEquals(1L, cantidadPerfiles, "El perfil en si no deberia haberse eliminado, solo la foto");
    }

    @Test
    void eliminarFotoDeberiaRechazarPosicionInexistente() {
        Long usuarioId = crearUsuarioRegistrado("profileeliminarfotoinexistente@integracion.com");

        ProfileRequest requestPerfil = ProfileRequest.builder()
                .bio("Perfil sin fotos")
                .build();
        profileService.crearPerfil(usuarioId, requestPerfil);

        assertThrows(RuntimeException.class, () -> {
            profileService.eliminarFoto(usuarioId, 3);
        }, "Deberia rechazar eliminar una foto que no existe en esa posicion");
    }
}