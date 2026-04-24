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
    @Column(name = "MENSAJE_ID")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_mensaje")
    @SequenceGenerator(name = "seq_mensaje",
            sequenceName = "SEQ_MENSAJE_ID",
            allocationSize = 1)
    private Long mensajeId;

    @Column(name = "MATCH_ID", nullable = false)
    private Long matchId;

    @Column(name = "EMISOR_ID", nullable = false)
    private Long emisorId;

    @Column(name = "CONTENIDO", nullable = false, length = 1000)
    private String contenido;

    @Column(name = "ESTADO", nullable = false, length = 10)
    private String estado;

    @CreationTimestamp
    @Column(name = "FECHA_ENVIO", nullable = false, updatable = false)
    private LocalDateTime fechaEnvio;

    @Column(name = "FECHA_LEIDO")
    private LocalDateTime fechaLeido;
}