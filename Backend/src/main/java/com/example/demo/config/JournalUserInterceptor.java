package com.example.demo.config;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.TypeEvenementUser;
import com.example.demo.service.JournalUserService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Enregistre automatiquement les creations, modifications et suppressions des
 * listes d'administration (racks, emplacements, societes, unites, types...).
 *
 * Un seul endroit pour une trentaine de routes : on regarde chaque requete
 * terminee avec succes, et on note l'action si son chemin est dans la liste.
 * Les actions metier (articles, journaux, stock...) sont enregistrees par les
 * services eux-memes, avec plus de details.
 */
@Component
public class JournalUserInterceptor implements HandlerInterceptor {

    private static final Logger LOGGER = LoggerFactory.getLogger(JournalUserInterceptor.class);

    // Premier segment du chemin -> type d'objet.
    private static final Map<String, CibleEvenement> REFERENTIELS = Map.ofEntries(
            Map.entry("rack", CibleEvenement.RACK),
            Map.entry("emplacements", CibleEvenement.EMPLACEMENT),
            Map.entry("societes", CibleEvenement.SOCIETE),
            Map.entry("unites", CibleEvenement.UNITE),
            Map.entry("types-produits", CibleEvenement.TYPE_PRODUIT),
            Map.entry("types-conditionnements", CibleEvenement.TYPE_CONDITIONNEMENT),
            Map.entry("articles-conditionnements", CibleEvenement.CONDITIONNEMENT),
            Map.entry("palettes-conditionnements", CibleEvenement.PALETTE),
            Map.entry("types-mouvements-journal", CibleEvenement.TYPE_MOUVEMENT),
            Map.entry("statuts-journaux-mouvements", CibleEvenement.STATUT),
            Map.entry("statuts-prelevements", CibleEvenement.STATUT),
            Map.entry("pickings", CibleEvenement.PICKING));

    private final JournalUserService journalUserService;

    public JournalUserInterceptor(JournalUserService journalUserService) {
        this.journalUserService = journalUserService;
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler,
            Exception exception) {

        TypeEvenementUser type = typeSelonVerbe(request.getMethod());
        if (type == null || exception != null || response.getStatus() >= 300) {
            return;
        }

        String[] segments = request.getRequestURI().split("/");
        // "/rack/5" -> ["", "rack", "5"]
        if (segments.length < 2) {
            return;
        }

        CibleEvenement cible = REFERENTIELS.get(segments[1]);
        if (cible == null) {
            return;
        }

        try {
            journalUserService.enregistrer(type, cible, dernierIdentifiant(segments), null);
        } catch (RuntimeException erreur) {
            // Une trace manquante ne doit jamais faire echouer une requete deja reussie.
            LOGGER.warn("Journal d'activite : enregistrement impossible ({})", erreur.getMessage());
        }
    }

    private TypeEvenementUser typeSelonVerbe(String methode) {
        return switch (methode) {
            case "POST" -> TypeEvenementUser.REFERENTIEL_CREE;
            case "PUT" -> TypeEvenementUser.REFERENTIEL_MODIFIE;
            case "DELETE" -> TypeEvenementUser.REFERENTIEL_SUPPRIME;
            default -> null;
        };
    }

    private Long dernierIdentifiant(String[] segments) {
        String dernier = segments[segments.length - 1];
        if (dernier.chars().allMatch(Character::isDigit) && !dernier.isEmpty()) {
            try {
                return Long.valueOf(dernier);
            } catch (NumberFormatException erreur) {
                return null;
            }
        }
        return null;
    }
}
