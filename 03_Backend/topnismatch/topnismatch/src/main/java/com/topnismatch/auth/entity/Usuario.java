package com.topnismatch.auth.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "USUARIO")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @Column(name = "USUARIO_ID")
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
                    generator = "seq_usuario")
    @SequenceGenerator(name = "seq_usuario",
                       sequenceName = "SEQ_USUARIO_ID",
                       allocationSize = 1)
    private Long usuarioId;

    @Column(name = "NOMBRE", nullable = false, length = 100)
    private String nombre;

    @Column(name = "EMAIL", nullable = false, unique = true, length = 150)
    private String email;

    @Column(name = "PASSWORD_HASH", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "FECHA_NACIMIENTO", nullable = false)
    private LocalDate fechaNacimiento;

    @Column(name = "GENERO", nullable = false, length = 20)
    private String genero;

    @Column(name = "ROL", nullable = false, length = 10)
    private String rol;

    @Column(name = "ACTIVO", nullable = false)
    private Integer activo;

    @Column(name = "EMAIL_VERIFICADO", nullable = false)
    private Integer emailVerificado;

    @CreationTimestamp
    @Column(name = "FECHA_REGISTRO", nullable = false, updatable = false)
    private LocalDateTime fechaRegistro;

    @UpdateTimestamp
    @Column(name = "FECHA_ACTUALIZACION", nullable = false)
    private LocalDateTime fechaActualizacion;
}