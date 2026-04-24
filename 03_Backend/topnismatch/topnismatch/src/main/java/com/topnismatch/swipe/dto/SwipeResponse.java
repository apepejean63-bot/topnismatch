package com.topnismatch.swipe.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SwipeResponse {

    private String resultado;
    private Boolean esMatch;
    private Long matchId;
    private String mensaje;

    public static SwipeResponse sinMatch(String tipo) {
        return SwipeResponse.builder()
                .resultado(tipo)
                .esMatch(false)
                .matchId(null)
                .mensaje("Accion registrada")
                .build();
    }

    public static SwipeResponse conMatch(Long matchId) {
        return SwipeResponse.builder()
                .resultado("LIKE")
                .esMatch(true)
                .matchId(matchId)
                .mensaje("Es un match!")
                .build();
    }
}