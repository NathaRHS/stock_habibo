package com.example.demo.config;

import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.example.demo.entity.Unite;
import com.example.demo.repository.UniteRepository;

/**
 * Au demarrage, ajoute les unites de contenance courantes si elles manquent.
 * Rejouable : une unite deja presente n'est jamais dupliquee.
 */
@Component
public class InitialiseurUnites implements ApplicationRunner {

    private static final List<String> UNITES_PAR_DEFAUT = List.of("g", "kg", "mL", "cL", "L");

    private final UniteRepository uniteRepository;

    public InitialiseurUnites(UniteRepository uniteRepository) {
        this.uniteRepository = uniteRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        for (String nom : UNITES_PAR_DEFAUT) {
            if (!uniteRepository.existsByNomUnite(nom)) {
                uniteRepository.save(new Unite(nom));
            }
        }
    }
}
