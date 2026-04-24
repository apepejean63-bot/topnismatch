package com.topnismatch.premium.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SuscripcionResponse {

    private Long suscripcionId;
    private String plan;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;
    private Boolean activo;
    private Boolean esPremium;
    private Long diasRestantes;
}