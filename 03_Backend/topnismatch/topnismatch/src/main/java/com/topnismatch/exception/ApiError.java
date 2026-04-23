package com.topnismatch.exception;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiError {

    private int status;
    private String error;
    private String mensaje;
    private LocalDateTime timestamp;

    public static ApiError of(int status, String error, String mensaje) {
        return ApiError.builder()
                .status(status)
                .error(error)
                .mensaje(mensaje)
                .timestamp(LocalDateTime.now())
                .build();
    }
}