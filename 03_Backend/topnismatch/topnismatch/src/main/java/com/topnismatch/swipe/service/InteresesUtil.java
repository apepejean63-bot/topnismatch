package com.topnismatch.swipe.service;

import java.text.Normalizer;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Normalizacion y comparacion de intereses para el matching.
 *
 * REGLA COMPARTIDA: Flutter debe aplicar la misma normalizacion para detectar
 * intereses en comun (lib/utils/interests.dart, pendiente de crear).
 * Si se cambia aqui, hay que cambiarla alla tambien.
 */
public final class InteresesUtil {

    private InteresesUtil() {
    }

    /**
     * Convierte un texto de intereses separados por coma en un conjunto de
     * valores normalizados. Ignora vacios y duplicados.
     */
    public static Set<String> normalizar(String intereses) {
        Set<String> resultado = new LinkedHashSet<>();
        if (intereses == null) {
            return resultado;
        }
        for (String parte : intereses.split(",")) {
            String normalizado = normalizarUno(parte);
            if (!normalizado.isEmpty()) {
                resultado.add(normalizado);
            }
        }
        return resultado;
    }

    /**
     * Quita tildes, descarta simbolos/emojis solo al INICIO del texto,
     * junta espacios multiples y pasa a minusculas. No toca los caracteres
     * del medio (por ejemplo "Rock & Roll" se conserva).
     */
    static String normalizarUno(String texto) {
        if (texto == null) {
            return "";
        }
        String s = Normalizer.normalize(texto, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        int i = 0;
        while (i < s.length()) {
            int cp = s.codePointAt(i);
            if (Character.isLetterOrDigit(cp)) {
                break;
            }
            i += Character.charCount(cp);
        }
        s = s.substring(i).replaceAll("(?U)\\s+", " ").strip();
        return s.toLowerCase(Locale.ROOT);
    }

    /**
     * Compatibilidad entre 0 y 100 segun intereses en comun.
     * Si alguno de los dos no tiene intereses validos devuelve 50 (neutro).
     */
    public static double compatibilidad(String interesesA, String interesesB) {
        Set<String> a = normalizar(interesesA);
        Set<String> b = normalizar(interesesB);
        if (a.isEmpty() || b.isEmpty()) {
            return 50.0;
        }
        Set<String> comunes = new HashSet<>(a);
        comunes.retainAll(b);
        double compatibilidad = (double) comunes.size() * 2 / (a.size() + b.size()) * 100;
        return Math.min(100.0, Math.max(0.0, compatibilidad));
    }
}