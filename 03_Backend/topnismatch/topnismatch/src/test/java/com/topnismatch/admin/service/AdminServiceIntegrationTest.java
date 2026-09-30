package com.topnismatch.admin.service;

import com.topnismatch.admin.dto.AdminReportResponse;
import com.topnismatch.admin.dto.AdminUserResponse;
import com.topnismatch.admin.dto.DashboardResponse;
import com.topnismatch.admin.dto.ResolveReportRequest;
import com.topnismatch.auth.dto.RegisterRequest;
import com.topnismatch.auth.service.AuthService;
import com.topnismatch.chat.dto.BlockReportRequest;
import com.topnismatch.chat.service.ChatService;
import com.topnismatch.premium.dto.UpgradeRequest;
import com.topnismatch.premium.service.PremiumService;
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

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Testcontainers
@Transactional
class AdminServiceIntegrationTest {

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
    private AdminService adminService;

    @Autowired
    private AuthService authService;

    @Autowired
    private PremiumService premiumService;

    @Autowired
    private ChatService chatService;

    @Autowired
    private EntityManager entityManager;

    private Long crearUsuarioRegistrado(String email) {
        RegisterRequest request = RegisterRequest.builder()
                .nombre("Admin Test")
                .email(email)
                .password("password123")
                .fechaNacimiento("1995-05-15")
                .genero("MASCULINO")
                .build();
        return authService.register(request).getUsuarioId();
    }

    @Test
    void obtenerDashboardDeberiaReflejarUsuariosCreados() {
        DashboardResponse antes = adminService.obtenerDashboard();

        crearUsuarioRegistrado("admindash1@integracion.com");
        crearUsuarioRegistrado("admindash2@integracion.com");

        DashboardResponse despues = adminService.obtenerDashboard();

        assertEquals(antes.getUsuariosTotales() + 2, despues.getUsuariosTotales(),
                "El total de usuarios deberia aumentar en 2");
        assertEquals(antes.getUsuariosActivos() + 2, despues.getUsuariosActivos(),
                "Los usuarios activos deberian aumentar en 2, ya que se registran activos por defecto");
        assertNotNull(despues.getUsuariosHoy());
        assertNotNull(despues.getMatchesTotales());
        assertNotNull(despues.getMensajesTotales());
        assertNotNull(despues.getSuscripcionesPremium());
        assertNotNull(despues.getReportesPendientes());
    }

    @Test
    void listarUsuariosDeberiaMostrarUsuariosConSuPlanCorrecto() {
        Long usuarioA = crearUsuarioRegistrado("adminlistgratuito@integracion.com");
        Long usuarioB = crearUsuarioRegistrado("adminlistpremium@integracion.com");

        UpgradeRequest upgradeRequest = new UpgradeRequest();
        upgradeRequest.setPlan("PREMIUM_MENSUAL");
        upgradeRequest.setReciboStore("recibo-admin-test");
        premiumService.upgradePremium(usuarioB, upgradeRequest);

        List<AdminUserResponse> usuarios = adminService.listarUsuarios();

        AdminUserResponse encontradoA = usuarios.stream()
                .filter(u -> u.getUsuarioId().equals(usuarioA))
                .findFirst()
                .orElse(null);
        assertNotNull(encontradoA, "Usuario A deberia aparecer en la lista");
        assertEquals("adminlistgratuito@integracion.com", encontradoA.getEmail());
        assertEquals("GRATUITO", encontradoA.getPlan());
        assertTrue(encontradoA.getActivo());

        AdminUserResponse encontradoB = usuarios.stream()
                .filter(u -> u.getUsuarioId().equals(usuarioB))
                .findFirst()
                .orElse(null);
        assertNotNull(encontradoB, "Usuario B deberia aparecer en la lista");
        assertEquals("adminlistpremium@integracion.com", encontradoB.getEmail());
        assertEquals("PREMIUM_MENSUAL", encontradoB.getPlan());
        assertEquals("PREMIUM", encontradoB.getRol());
    }

    @Test
    void cambiarEstadoUsuarioDeberiaDesactivarlo() {
        Long usuarioId = crearUsuarioRegistrado("admindesactivar@integracion.com");

        Boolean activoAntes = (Boolean) entityManager.createNativeQuery(
                        "SELECT CASE WHEN activo = 1 THEN true ELSE false END FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult();
        assertTrue(activoAntes, "El usuario deberia estar activo justo despues de registrarse");

        AdminUserResponse respuesta = adminService.cambiarEstadoUsuario(usuarioId, false);

        assertFalse(respuesta.getActivo(), "La respuesta deberia indicar que el usuario quedo inactivo");

        Boolean activoDespues = (Boolean) entityManager.createNativeQuery(
                        "SELECT CASE WHEN activo = 1 THEN true ELSE false END FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult();
        assertFalse(activoDespues, "El usuario deberia quedar inactivo en la base de datos");
    }

    @Test
    void cambiarEstadoUsuarioDeberiaReactivarlo() {
        Long usuarioId = crearUsuarioRegistrado("adminreactivar@integracion.com");

        adminService.cambiarEstadoUsuario(usuarioId, false);
        AdminUserResponse respuesta = adminService.cambiarEstadoUsuario(usuarioId, true);

        assertTrue(respuesta.getActivo(), "La respuesta deberia indicar que el usuario quedo activo nuevamente");

        Boolean activoEnBD = (Boolean) entityManager.createNativeQuery(
                        "SELECT CASE WHEN activo = 1 THEN true ELSE false END FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioId)
                .getSingleResult();
        assertTrue(activoEnBD, "El usuario deberia quedar activo nuevamente en la base de datos");
    }

    @Test
    void listarReportesDeberiaMostrarElReporteCreado() {
        Long usuarioA = crearUsuarioRegistrado("adminreportante@integracion.com");
        Long usuarioB = crearUsuarioRegistrado("adminreportado@integracion.com");

        BlockReportRequest reportRequest = new BlockReportRequest();
        reportRequest.setCategoria("CONTENIDO_INAPROPIADO");
        reportRequest.setDescripcion("Reporte de prueba para admin");
        chatService.reportarUsuario(usuarioA, usuarioB, reportRequest);

        List<AdminReportResponse> reportes = adminService.listarReportes(null);

        AdminReportResponse encontrado = reportes.stream()
                .filter(r -> r.getUsuarioDenuncianteId().equals(usuarioA)
                        && r.getUsuarioDenunciadoId().equals(usuarioB))
                .findFirst()
                .orElse(null);

        assertNotNull(encontrado, "El reporte creado deberia aparecer en la lista");
        assertEquals("CONTENIDO_INAPROPIADO", encontrado.getCategoria());
        assertEquals("Reporte de prueba para admin", encontrado.getDescripcion());
        assertEquals("PENDIENTE", encontrado.getEstado());
        assertNotNull(encontrado.getFechaReporte());
        assertNull(encontrado.getFechaResolucion(), "Un reporte recien creado no deberia tener fecha de resolucion");
    }
    @Test
    void resolverReporteDeberiaActualizarEstadoYBloquearUsuario() {
        Long usuarioAdmin = crearUsuarioRegistrado("adminresolutor@integracion.com");
        Long usuarioA = crearUsuarioRegistrado("adminresolverreportante@integracion.com");
        Long usuarioB = crearUsuarioRegistrado("adminresolverreportado@integracion.com");

        BlockReportRequest reportRequest = new BlockReportRequest();
        reportRequest.setCategoria("ACOSO");
        reportRequest.setDescripcion("Reporte a resolver");
        chatService.reportarUsuario(usuarioA, usuarioB, reportRequest);

        List<AdminReportResponse> reportesPendientes = adminService.listarReportes("PENDIENTE");
        AdminReportResponse reporteCreado = reportesPendientes.stream()
                .filter(r -> r.getUsuarioDenuncianteId().equals(usuarioA)
                        && r.getUsuarioDenunciadoId().equals(usuarioB))
                .findFirst()
                .orElse(null);
        assertNotNull(reporteCreado, "El reporte deberia aparecer entre los pendientes");

        ResolveReportRequest resolveRequest = new ResolveReportRequest();
        resolveRequest.setEstado("RESUELTO");
        resolveRequest.setNotaAdmin("Se verifico el acoso, usuario bloqueado");
        resolveRequest.setBloquearUsuario(true);

        AdminReportResponse respuesta = adminService.resolverReporte(
                reporteCreado.getReporteId(), usuarioAdmin, resolveRequest);

        assertEquals("RESUELTO", respuesta.getEstado());
        assertEquals("Se verifico el acoso, usuario bloqueado", respuesta.getNotaAdmin());
        assertEquals(reporteCreado.getReporteId(), respuesta.getReporteId(),
                "Deberia ser el mismo reporte, no uno nuevo");

        Boolean usuarioActivoEnBD = (Boolean) entityManager.createNativeQuery(
                        "SELECT CASE WHEN activo = 1 THEN true ELSE false END FROM USUARIO WHERE usuario_id = :userId")
                .setParameter("userId", usuarioB)
                .getSingleResult();
        assertFalse(usuarioActivoEnBD, "El usuario denunciado deberia quedar desactivado al resolver con bloquearUsuario=true");

        String adminResolutorEnBD = ((Number) entityManager.createNativeQuery(
                        "SELECT admin_resolutor_id FROM REPORTE WHERE reporte_id = :id")
                .setParameter("id", reporteCreado.getReporteId())
                .getSingleResult()).toString();
        assertEquals(usuarioAdmin.toString(), adminResolutorEnBD,
                "El admin resolutor deberia quedar registrado en el reporte");
    }
    @Test
    void listarReportesConEstadoMaliciosoNoDeberiaAlterarLaConsulta() {
        Long usuarioA = crearUsuarioRegistrado("adminseguridada@integracion.com");
        Long usuarioB = crearUsuarioRegistrado("adminseguridadb@integracion.com");

        BlockReportRequest reportRequest = new BlockReportRequest();
        reportRequest.setCategoria("SPAM");
        reportRequest.setDescripcion("Reporte para prueba de seguridad");
        chatService.reportarUsuario(usuarioA, usuarioB, reportRequest);

        String payloadMalicioso = "PENDIENTE' OR '1'='1";

        List<AdminReportResponse> resultado = adminService.listarReportes(payloadMalicioso);

        assertTrue(resultado.isEmpty(),
                "Un estado que no existe literalmente no deberia devolver ningun reporte, " +
                "incluso si el texto contiene una condicion SQL como OR '1'='1'");
    }
}