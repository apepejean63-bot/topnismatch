package com.topnismatch.auth.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {

    private String token;
    private String tipo;
    private Long usuarioId;
    private String nombre;
    private String email;
    private String rol;
    private String plan;

    public static AuthResponse of(String token, Long usuarioId,
                                   String nombre, String email,
                                   String rol, String plan) {
        return AuthResponse.builder()
                .token(token)
                .tipo("Bearer")
                .usuarioId(usuarioId)
                .nombre(nombre)
                .email(email)
                .rol(rol)
                .plan(plan)
                .build();
    }
}