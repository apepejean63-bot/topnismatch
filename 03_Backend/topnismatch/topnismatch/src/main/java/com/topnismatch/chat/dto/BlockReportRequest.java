package com.topnismatch.chat.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class BlockReportRequest {

    @Size(max = 300, message = "La descripcion no puede superar 300 caracteres")
    private String descripcion;

    @Pattern(regexp = "SPAM|ACOSO|PERFIL_FALSO|CONTENIDO_INAPROPIADO|OTRO",
            message = "Categoria invalida")
    private String categoria;
}