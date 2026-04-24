package com.topnismatch.profile.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FotoRequest {

    @NotBlank(message = "La URL de la foto es obligatoria")
    @Size(max = 500, message = "La URL no puede superar 500 caracteres")
    private String url;

    @NotNull(message = "El orden es obligatorio")
    @Min(value = 1, message = "El orden minimo es 1")
    @Max(value = 6, message = "El orden maximo es 6")
    private Integer orden;
}