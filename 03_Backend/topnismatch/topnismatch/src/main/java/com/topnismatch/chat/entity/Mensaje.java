package com.topnismatch.chat.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "MENSAJE")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Mensaje {

    @Id
    @Column(name = "mensaje_id")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_mensaje")
    @SequenceGenerator(name = "seq_mensaje",
            sequenceName = "seq_mensaje_id",
            allocationSize = 1)
    private Long mensajeId;

    @Column(name = "match_id", nullable = false)
    private Long matchId;

    @Column(name = "emisor_id", nullable = false)
    private Long emisorId;

    @Column(name = "contenido", nullable = false, length = 1000)
    private String contenido;

    @Column(name = "estado", nullable = false, length = 10)
    private String estado;

    @CreationTimestamp
    @Column(name = "fecha_envio", nullable = false, updatable = false)
    private LocalDateTime fechaEnvio;

    @Column(name = "fecha_leido")
    private LocalDateTime fechaLeido;
}