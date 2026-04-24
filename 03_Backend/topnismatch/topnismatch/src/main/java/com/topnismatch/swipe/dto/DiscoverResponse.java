package com.topnismatch.swipe.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiscoverResponse {

    private Long usuarioId;
    private Long perfilId;
    private String nombre;
    private Integer edad;
    private String bio;
    private String ciudad;
    private String intereses;
    private String fotoPrincipalUrl;
    private List<String> fotosUrls;
}