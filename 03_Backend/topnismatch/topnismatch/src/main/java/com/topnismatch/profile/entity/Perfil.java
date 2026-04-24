package com.topnismatch.profile.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "PERFIL")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Perfil {

    @Id
    @Column(name = "PERFIL_ID")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_perfil")
    @SequenceGenerator(name = "seq_perfil",
            sequenceName = "SEQ_PERFIL_ID",
            allocationSize = 1)
    private Long perfilId;

    @Column(name = "USUARIO_ID", nullable = false, unique = true)
    private Long usuarioId;

    @Column(name = "BIO", length = 500)
    private String bio;

    @Column(name = "CIUDAD", length = 100)
    private String ciudad;

    @Column(name = "OBJETIVO", nullable = false, length = 30)
    private String objetivo;

    @Column(name = "INTERESES", length = 1000)
    private String intereses;

    @Column(name = "EDAD_MIN_BUSCADA", nullable = false)
    private Integer edadMinBuscada;

    @Column(name = "EDAD_MAX_BUSCADA", nullable = false)
    private Integer edadMaxBuscada;

    @Column(name = "DISTANCIA_MAX_KM", nullable = false)
    private Integer distanciaMaxKm;

    @Column(name = "GENERO_BUSCADO", length = 20)
    private String generoBuscado;

    @Column(name = "FOTO_PRINCIPAL_ID")
    private Long fotoPrincipalId;

    @UpdateTimestamp
    @Column(name = "FECHA_ACTUALIZACION", nullable = false)
    private LocalDateTime fechaActualizacion;
}