package com.topnismatch.premium.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class NotifConfigRequest {

    private Boolean notifMatches;
    private Boolean notifMensajes;
    private Boolean notifSuperLikes;
    private Boolean notifVistasPerfil;
    private String silencioInicio;
    private String silencioFin;
}