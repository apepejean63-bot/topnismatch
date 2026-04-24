package com.topnismatch.chat.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MensajeResponse {

    private Long mensajeId;
    private Long matchId;
    private Long emisorId;
    private String emisorNombre;
    private String contenido;
    private String estado;
    private LocalDateTime fechaEnvio;
    private LocalDateTime fechaLeido;
}