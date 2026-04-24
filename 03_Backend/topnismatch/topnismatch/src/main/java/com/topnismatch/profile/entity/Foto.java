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
    @Column(name = "FOTO_ID")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_foto")
    @SequenceGenerator(name = "seq_foto",
            sequenceName = "SEQ_FOTO_ID",
            allocationSize = 1)
    private Long fotoId;

    @Column(name = "USUARIO_ID", nullable = false)
    private Long usuarioId;

    @Column(name = "URL", nullable = false, length = 500)
    private String url;

    @Column(name = "ORDEN", nullable = false)
    private Integer orden;

    @CreationTimestamp
    @Column(name = "FECHA_SUBIDA", nullable = false, updatable = false)
    private LocalDateTime fechaSubida;
}