package com.example.demo.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.nio.charset.StandardCharsets;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

class CsvServiceTest {

    private final CsvService csvService = new CsvService();

    private MockMultipartFile fichier(String contenu) {
        return new MockMultipartFile("file", "test.csv", "text/csv",
                contenu.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void ecrireEtRelireGardeAccentsSeparateursEtGuillemets() {
        List<String> entetes = List.of("nom", "note");
        List<List<String>> lignes = List.of(
                List.of("Café; crème", "dit \"bon\""),
                List.of("Eau", ""));

        byte[] octets = csvService.ecrire(entetes, lignes);
        List<List<String>> relu = csvService.lire(fichier(new String(octets, StandardCharsets.UTF_8)));

        assertEquals(3, relu.size());
        assertEquals(entetes, relu.get(0));
        assertEquals(List.of("Café; crème", "dit \"bon\""), relu.get(1));
        assertEquals(List.of("Eau", ""), relu.get(2));
    }

    @Test
    void lireAccepteLaVirguleEtLesFinsDeLigneWindows() {
        List<List<String>> lignes = csvService.lire(fichier("a,b\r\n1,2\r\n3,4"));

        assertEquals(3, lignes.size());
        assertEquals(List.of("3", "4"), lignes.get(2));
    }

    @Test
    void lireGardeLesLignesVidesPourLaNumerotation() {
        List<List<String>> lignes = csvService.lire(fichier("a;b\n\n1;2\n"));

        assertEquals(3, lignes.size());
        assertEquals(List.of(""), lignes.get(1));
        assertEquals(List.of("1", "2"), lignes.get(2));
    }
}
