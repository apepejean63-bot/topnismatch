package com.topnismatch.chat.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class MensajeRequest {

    @NotBlank(message = "El contenido es obligatorio")
    @Size(min = 1, max = 1000, message = "El mensaje debe tener entre 1 y 1000 caracteres")
    private String contenido;
}