package com.topnismatch.premium.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotifConfigResponse {

    private Long notifPrefId;
    private Boolean notifMatches;
    private Boolean notifMensajes;
    private Boolean notifSuperLikes;
    private Boolean notifVistasPerfil;
    private String silencioInicio;
    private String silencioFin;
}