package com.example.demo.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.example.demo.entity.CleParametreSuggestion;
import com.example.demo.entity.ParametreSuggestion;
import com.example.demo.repository.ParametreSuggestionRepository;

/**
 * Au demarrage, ajoute les reglages de la suggestion qui manquent, avec leur
 * valeur par defaut. Rejouable : un reglage deja present (et peut-etre modifie)
 * n'est jamais ecrase.
 */
@Component
public class InitialiseurParametresSuggestion implements ApplicationRunner {

    private final ParametreSuggestionRepository parametreRepository;

    public InitialiseurParametresSuggestion(ParametreSuggestionRepository parametreRepository) {
        this.parametreRepository = parametreRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        for (CleParametreSuggestion cle : CleParametreSuggestion.values()) {
            if (!parametreRepository.existsById(cle.getCle())) {
                parametreRepository.save(new ParametreSuggestion(
                        cle.getCle(), cle.getValeurParDefaut(), cle.getDescription()));
            }
        }
    }
}
