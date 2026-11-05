package com.example.demo.service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/**
 * Lecture et ecriture de fichiers CSV, partagees par tous les imports et exports.
 * Ecriture : separateur ";" et UTF-8 avec BOM, pour qu'Excel en francais ouvre le
 * fichier sans casser les accents. Lecture : ";" ou "," selon la premiere ligne.
 */
@Service
public class CsvService {

    private static final String BOM = "﻿";
    private static final char SEPARATEUR_ECRITURE = ';';

    /** Renvoie toutes les lignes, en-tete compris. Les lignes vides sont conservees (numerotation fidele). */
    public List<List<String>> lire(MultipartFile fichier) {
        if (fichier == null || fichier.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le fichier est vide");
        }

        String texte;
        try {
            texte = new String(fichier.getBytes(), StandardCharsets.UTF_8);
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Impossible de lire le fichier", exception);
        }
        if (texte.startsWith(BOM)) {
            texte = texte.substring(1);
        }

        char separateur = choisirSeparateur(texte);
        List<List<String>> lignes = new ArrayList<>();
        List<String> ligne = new ArrayList<>();
        StringBuilder champ = new StringBuilder();
        boolean entreGuillemets = false;

        for (int i = 0; i < texte.length(); i++) {
            char c = texte.charAt(i);

            if (entreGuillemets) {
                if (c == '"') {
                    if (i + 1 < texte.length() && texte.charAt(i + 1) == '"') {
                        champ.append('"');
                        i++;
                    } else {
                        entreGuillemets = false;
                    }
                } else {
                    champ.append(c);
                }
            } else if (c == '"') {
                entreGuillemets = true;
            } else if (c == separateur) {
                ligne.add(champ.toString());
                champ.setLength(0);
            } else if (c == '\n' || c == '\r') {
                if (c == '\r' && i + 1 < texte.length() && texte.charAt(i + 1) == '\n') {
                    i++;
                }
                ligne.add(champ.toString());
                champ.setLength(0);
                lignes.add(ligne);
                ligne = new ArrayList<>();
            } else {
                champ.append(c);
            }
        }

        // Derniere ligne sans retour a la ligne final.
        if (champ.length() > 0 || !ligne.isEmpty()) {
            ligne.add(champ.toString());
            lignes.add(ligne);
        }

        return lignes;
    }

    /** Ecrit un fichier CSV (en-tete puis lignes) pret a etre telecharge. */
    public byte[] ecrire(List<String> entetes, List<List<String>> lignes) {
        StringBuilder texte = new StringBuilder(BOM);
        ajouterLigne(texte, entetes);
        for (List<String> ligne : lignes) {
            ajouterLigne(texte, ligne);
        }
        return texte.toString().getBytes(StandardCharsets.UTF_8);
    }

    private char choisirSeparateur(String texte) {
        int fin = texte.indexOf('\n');
        String premiereLigne = fin < 0 ? texte : texte.substring(0, fin);
        if (premiereLigne.indexOf(';') >= 0) {
            return ';';
        }
        return premiereLigne.indexOf(',') >= 0 ? ',' : ';';
    }

    private void ajouterLigne(StringBuilder texte, List<String> valeurs) {
        for (int i = 0; i < valeurs.size(); i++) {
            if (i > 0) {
                texte.append(SEPARATEUR_ECRITURE);
            }
            texte.append(echapper(valeurs.get(i)));
        }
        texte.append("\r\n");
    }

    private String echapper(String valeur) {
        if (valeur == null) {
            return "";
        }
        boolean aProteger = valeur.indexOf(SEPARATEUR_ECRITURE) >= 0
                || valeur.indexOf('"') >= 0
                || valeur.indexOf('\n') >= 0
                || valeur.indexOf('\r') >= 0;
        return aProteger ? "\"" + valeur.replace("\"", "\"\"") + "\"" : valeur;
    }
}
