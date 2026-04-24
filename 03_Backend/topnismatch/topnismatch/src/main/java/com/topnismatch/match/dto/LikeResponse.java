package com.topnismatch.match.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LikeResponse {

    private Long usuarioId;
    private String nombre;
    private String fotoUrl;
    private String tipoLike;
    private LocalDateTime fechaLike;
}