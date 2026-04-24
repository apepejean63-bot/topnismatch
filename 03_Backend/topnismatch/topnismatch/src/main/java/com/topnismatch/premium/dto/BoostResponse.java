package com.topnismatch.premium.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BoostResponse {

    private Long boostId;
    private LocalDateTime fechaActivacion;
    private LocalDateTime fechaFin;
    private Boolean activo;
    private String mensaje;
}