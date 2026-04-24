package com.topnismatch.profile.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileRequest {

    @Size(max = 500, message = "La bio no puede superar 500 caracteres")
    private String bio;

    @Size(max = 100, message = "La ciudad no puede superar 100 caracteres")
    private String ciudad;

    @Size(max = 1000, message = "Los intereses no pueden superar 1000 caracteres")
    private String intereses;

    @Min(value = 18, message = "La edad minima buscada debe ser al menos 18")
    @Max(value = 99, message = "La edad minima buscada no puede superar 99")
    private Integer edadMinBuscada;

    @Min(value = 18, message = "La edad maxima buscada debe ser al menos 18")
    @Max(value = 99, message = "La edad maxima buscada no puede superar 99")
    private Integer edadMaxBuscada;

    @Min(value = 1, message = "La distancia minima es 1 km")
    @Max(value = 500, message = "La distancia maxima es 500 km")
    private Integer distanciaMaxKm;

    @Pattern(regexp = "MASCULINO|FEMENINO|NO_BINARIO|PREFIERO_NO_DECIR",
            message = "Genero invalido")
    private String generoBuscado;
}