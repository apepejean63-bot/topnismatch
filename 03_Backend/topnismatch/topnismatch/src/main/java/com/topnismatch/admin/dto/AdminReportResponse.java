package com.topnismatch.admin.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminReportResponse {

    private Long reporteId;
    private Long usuarioDenuncianteId;
    private String nombreDenunciante;
    private Long usuarioDenunciadoId;
    private String nombreDenunciado;
    private String categoria;
    private String descripcion;
    private String estado;
    private String notaAdmin;
    private LocalDateTime fechaReporte;
    private LocalDateTime fechaResolucion;
}