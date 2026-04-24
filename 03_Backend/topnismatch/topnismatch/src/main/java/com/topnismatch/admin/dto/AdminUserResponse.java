package com.topnismatch.admin.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminUserResponse {

    private Long usuarioId;
    private String nombre;
    private String email;
    private String rol;
    private Boolean activo;
    private Boolean emailVerificado;
    private String plan;
    private LocalDateTime fechaRegistro;
}