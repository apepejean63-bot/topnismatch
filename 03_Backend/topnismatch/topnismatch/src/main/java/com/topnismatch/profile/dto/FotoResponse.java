package com.topnismatch.profile.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FotoResponse {

    private Long fotoId;
    private String url;
    private Integer orden;
}