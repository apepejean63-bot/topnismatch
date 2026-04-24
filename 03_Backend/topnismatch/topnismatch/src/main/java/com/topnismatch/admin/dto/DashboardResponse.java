package com.topnismatch.admin.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardResponse {

    private Long usuariosTotales;
    private Long usuariosActivos;
    private Long usuariosHoy;
    private Long matchesTotales;
    private Long matchesHoy;
    private Long mensajesTotales;
    private Long suscripcionesPremium;
    private Long reportesPendientes;
}