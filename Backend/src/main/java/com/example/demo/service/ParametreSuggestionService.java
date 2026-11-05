package com.example.demo.service;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.optimisation.ParametreSuggestionRequest;
import com.example.demo.dto.optimisation.ParametreSuggestionResponse;
import com.example.demo.entity.CleParametreSuggestion;
import com.example.demo.entity.ParametreSuggestion;
import com.example.demo.repository.ParametreSuggestionRepository;

/** Lecture des reglages de la suggestion : la valeur enregistree, sinon celle par defaut. */
@Service
public class ParametreSuggestionService {

    private final ParametreSuggestionRepository parametreRepository;

    public ParametreSuggestionService(ParametreSuggestionRepository parametreRepository) {
        this.parametreRepository = parametreRepository;
    }

    /** Tous les reglages, dans l'ordre de la liste fermee (valeur enregistree ou par defaut). */
    public List<ParametreSuggestionResponse> lister() {
        return Arrays.stream(CleParametreSuggestion.values())
                .map(cle -> new ParametreSuggestionResponse(cle.getCle(), valeur(cle), cle.getDescription()))
                .toList();
    }

    /** Enregistre les reglages recus. Tout est verifie avant d'ecrire quoi que ce soit. */
    @Transactional
    public List<ParametreSuggestionResponse> modifier(List<ParametreSuggestionRequest> demandes) {
        if (demandes == null || demandes.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Aucun reglage a enregistrer");
        }

        // Valeurs finales : celles du serveur, remplacees par celles recues.
        Map<CleParametreSuggestion, BigDecimal> finales = new EnumMap<>(CleParametreSuggestion.class);
        for (CleParametreSuggestion cle : CleParametreSuggestion.values()) {
            finales.put(cle, valeur(cle));
        }

        for (ParametreSuggestionRequest demande : demandes) {
            CleParametreSuggestion cle = trouverCle(demande.cle());
            if (demande.valeur() == null || demande.valeur().signum() < 0) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Le reglage " + cle.getCle() + " doit etre positif ou nul");
            }
            finales.put(cle, demande.valeur());
        }

        verifierPoids(finales);
        verifierScoreVide(finales);

        for (ParametreSuggestionRequest demande : demandes) {
            CleParametreSuggestion cle = trouverCle(demande.cle());
            ParametreSuggestion parametre = parametreRepository.findById(cle.getCle())
                    .orElseGet(() -> new ParametreSuggestion(
                            cle.getCle(), cle.getValeurParDefaut(), cle.getDescription()));
            parametre.setValeur(demande.valeur());
            parametreRepository.save(parametre);
        }
        return lister();
    }

    private CleParametreSuggestion trouverCle(String nom) {
        for (CleParametreSuggestion cle : CleParametreSuggestion.values()) {
            if (cle.getCle().equals(nom)) {
                return cle;
            }
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reglage inconnu : " + nom);
    }

    // Les quatre poids doivent faire 100 au total.
    private void verifierPoids(Map<CleParametreSuggestion, BigDecimal> valeurs) {
        BigDecimal total = valeurs.get(CleParametreSuggestion.POIDS_PROXIMITE)
                .add(valeurs.get(CleParametreSuggestion.POIDS_CAPACITE))
                .add(valeurs.get(CleParametreSuggestion.POIDS_FIABILITE))
                .add(valeurs.get(CleParametreSuggestion.POIDS_REGROUPEMENT));
        if (total.compareTo(new BigDecimal("100")) != 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Les poids doivent faire 100 au total (actuellement " + total.stripTrailingZeros().toPlainString() + ")");
        }
    }

    private void verifierScoreVide(Map<CleParametreSuggestion, BigDecimal> valeurs) {
        BigDecimal score = valeurs.get(CleParametreSuggestion.SCORE_EMPLACEMENT_VIDE);
        if (score.compareTo(new BigDecimal("100")) > 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le score d'un emplacement vide est compris entre 0 et 100");
        }
    }

    public BigDecimal valeur(CleParametreSuggestion cle) {
        return parametreRepository.findById(cle.getCle())
                .map(parametre -> parametre.getValeur())
                .orElse(cle.getValeurParDefaut());
    }

    public double valeurDecimale(CleParametreSuggestion cle) {
        return valeur(cle).doubleValue();
    }
}
