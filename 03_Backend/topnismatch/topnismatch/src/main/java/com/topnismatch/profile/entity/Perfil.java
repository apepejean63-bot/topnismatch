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
    @Column(name = "perfil_id")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "seq_perfil")
    @SequenceGenerator(name = "seq_perfil",
            sequenceName = "seq_perfil_id",
            allocationSize = 1)
    private Long perfilId;

    @Column(name = "usuario_id", nullable = false, unique = true)
    private Long usuarioId;

    @Column(name = "bio", length = 500)
    private String bio;

    @Column(name = "ciudad", length = 100)
    private String ciudad;

    @Column(name = "objetivo", nullable = false, length = 30)
    private String objetivo;

    @Column(name = "intereses", length = 1000)
    private String intereses;

    @Column(name = "edad_min_buscada", nullable = false)
    private Integer edadMinBuscada;

    @Column(name = "edad_max_buscada", nullable = false)
    private Integer edadMaxBuscada;

    @Column(name = "distancia_max_km", nullable = false)
    private Integer distanciaMaxKm;

    @Column(name = "genero_buscado", length = 20)
    private String generoBuscado;

    @Column(name = "foto_principal_id")
    private Long fotoPrincipalId;

    @UpdateTimestamp
    @Column(name = "fecha_actualizacion", nullable = false)
    private LocalDateTime fechaActualizacion;

    @Column(name = "profesion", length = 100)
    private String profesion;

    @Column(name = "educacion", length = 100)
    private String educacion;

    @Column(name = "idioma", length = 50)
    private String idioma;

    @Column(name = "signo_zodiacal", length = 50)
    private String signoZodiacal;

    @Column(name = "mascotas", length = 50)
    private String mascotas;

    @Column(name = "alcohol", length = 50)
    private String alcohol;

    @Column(name = "tabaco", length = 50)
    private String tabaco;

    @Column(name = "ejercicio", length = 50)
    private String ejercicio;

    @Column(name = "tiene_hijos", length = 50)
    private String tieneHijos;

    @Column(name = "quiere_hijos", length = 50)
    private String quiereHijos;

    @Column(name = "religion", length = 50)
    private String religion;
}