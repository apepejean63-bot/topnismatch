package com.topnismatch.profile.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "FOTO")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Foto {

    @Id
    @Column(name = "foto_id")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_foto")
    @SequenceGenerator(name = "seq_foto",
            sequenceName = "seq_foto_id",
            allocationSize = 1)
    private Long fotoId;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    @Column(name = "url", nullable = false, length = 500)
    private String url;

    @Column(name = "orden", nullable = false)
    private Integer orden;

    @CreationTimestamp
    @Column(name = "fecha_subida", nullable = false, updatable = false)
    private LocalDateTime fechaSubida;
}