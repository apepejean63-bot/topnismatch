package com.topnismatch.profile.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileResponse {

    private Long perfilId;
    private Long usuarioId;
    private String nombre;
    private String bio;
    private String ciudad;
    private String objetivo;
    private String intereses;
    private Integer edadMinBuscada;
    private Integer edadMaxBuscada;
    private Integer distanciaMaxKm;
    private String generoBuscado;
    private Long fotoPrincipalId;
    private List<FotoResponse> fotos;
    private String profesion;
    private String educacion;
    private String idioma;
    private String signoZodiacal;
    private String mascotas;
    private String alcohol;
    private String tabaco;
    private String ejercicio;
    private String tieneHijos;
    private String quiereHijos;
    private String religion;
}