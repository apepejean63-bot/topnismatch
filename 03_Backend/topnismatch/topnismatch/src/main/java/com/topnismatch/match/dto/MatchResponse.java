package com.topnismatch.match.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MatchResponse {

    private Long matchId;
    private Long otroUsuarioId;
    private String otroUsuarioNombre;
    private String otroUsuarioFotoUrl;
    private Double compatibilidad;
    private LocalDateTime fechaMatch;
    private Boolean activo;
}