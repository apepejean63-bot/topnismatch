package com.topnismatch.admin.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ResolveReportRequest {

    @NotBlank(message = "El estado es obligatorio")
    @Pattern(regexp = "EN_REVISION|RESUELTO",
            message = "Estado invalido")
    private String estado;

    @Size(max = 500, message = "La nota no puede superar 500 caracteres")
    private String notaAdmin;

    private Boolean bloquearUsuario;
}