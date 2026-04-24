package com.topnismatch.premium.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpgradeRequest {

    @NotBlank(message = "El plan es obligatorio")
    @Pattern(regexp = "PREMIUM_MENSUAL|PREMIUM_ANUAL",
            message = "Plan invalido. Debe ser PREMIUM_MENSUAL o PREMIUM_ANUAL")
    private String plan;

    private String reciboStore;
}