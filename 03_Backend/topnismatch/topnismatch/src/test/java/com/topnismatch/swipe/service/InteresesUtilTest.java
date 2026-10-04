package com.topnismatch.swipe.service;

import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class InteresesUtilTest {

    // U+1F3B5 (nota musical) y U+26BD (balon), escritos con escapes
    private static final String MUSICA_CON_EMOJI = "\uD83C\uDFB5 M\u00FAsica";
    private static final String FUTBOL_CON_EMOJI = "\u26BD F\u00FAtbol";

    @Test
    void emojiTildesYMayusculasSeNormalizanIgual() {
        assertEquals(Set.of("musica", "futbol"),
                InteresesUtil.normalizar(MUSICA_CON_EMOJI + ", " + FUTBOL_CON_EMOJI));
        assertEquals(Set.of("musica", "futbol"),
                InteresesUtil.normalizar("MUSICA,futbol"));
    }

    @Test
    void compatibilidadConEmojisYSinEmojisEs100() {
        double resultado = InteresesUtil.compatibilidad(
                MUSICA_CON_EMOJI + ", F\u00FAtbol", "musica,futbol");
        assertEquals(100.0, resultado, 0.0001);
    }

    @Test
    void espaciosYDuplicadosNoAlteranElResultado() {
        double resultado = InteresesUtil.compatibilidad(
                "M\u00FAsica,   M\u00FAsica ,F\u00FAtbol", "futbol,  MUSICA");
        assertEquals(100.0, resultado, 0.0001);
    }

    @Test
    void interesesVaciosDevuelvenNeutro50() {
        assertEquals(50.0, InteresesUtil.compatibilidad("", "M\u00FAsica"), 0.0001);
        assertEquals(50.0, InteresesUtil.compatibilidad(null, "M\u00FAsica"), 0.0001);
        assertEquals(50.0, InteresesUtil.compatibilidad(" , ,", "M\u00FAsica"), 0.0001);
        assertEquals(50.0, InteresesUtil.compatibilidad("", ""), 0.0001);
    }

    @Test
    void caracteresInternosNoSeAlteran() {
        assertTrue(InteresesUtil.normalizar("Rock & Roll").contains("rock & roll"));
        assertTrue(InteresesUtil.normalizar("3D printing").contains("3d printing"));
    }

    @Test
    void sinCoincidenciasDa0() {
        assertEquals(0.0, InteresesUtil.compatibilidad("M\u00FAsica", "Cine"), 0.0001);
    }

    @Test
    void coincidenciaParcialCalculaProporcion() {
        assertEquals(50.0, InteresesUtil.compatibilidad("M\u00FAsica,Cine", "M\u00FAsica,Viajes"), 0.0001);
    }

    @Test
    void simbolosAlInicioSeIgnoran() {
        assertEquals(Set.of("viajes"), InteresesUtil.normalizar("\u2708\uFE0F Viajes"));
        assertEquals(Set.of("viajes"), InteresesUtil.normalizar("- Viajes"));
        assertEquals(Set.of("viajes"), InteresesUtil.normalizar("  +  Viajes "));
    }
}