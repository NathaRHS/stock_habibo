package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.picking.PickingCreateRequest;
import com.example.demo.dto.picking.PickingResponse;
import com.example.demo.dto.picking.PickingUpdateRequest;
import com.example.demo.entity.HistoriquePickingStatut;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Rack;
import com.example.demo.entity.Role;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutPicking;
import com.example.demo.entity.StatutPickingCode;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.User;
import com.example.demo.repository.HistoriquePickingStatutRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.StatutPickingRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.UserRepository;

/**
 * Simule la vie d'un picking sur une base H2 en memoire : generation, demarrage,
 * fin ou annulation. Verifie que chaque changement de statut ajoute une ligne
 * d'historique et que les transitions interdites n'en ajoutent aucune.
 */
@DataJpaTest(properties = {
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Import({ PickingService.class, PickingStatutService.class, LignePickingStatutService.class })
class PickingStatutHistoriqueTest {

    private static final String MATRICULE = "M001";

    @Autowired
    private PickingService pickingService;

    @Autowired
    private HistoriquePickingStatutRepository historiqueRepository;

    @Autowired
    private StatutPickingRepository statutPickingRepository;

    @Autowired
    private StatutJournalMouvementRepository statutJournalRepository;

    @Autowired
    private TypeMouvementJournalRepository typeRepository;

    @Autowired
    private JournalMouvementRepository journalRepository;

    @Autowired
    private RackRepository rackRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    private Long journalId;
    private Long userId;
    private Long rackId;

    @BeforeEach
    void preparerDonnees() {
        for (StatutPickingCode code : StatutPickingCode.values()) {
            statutPickingRepository.save(new StatutPicking(code.getNom()));
        }

        StatutJournalMouvement statutJournal = statutJournalRepository.save(new StatutJournalMouvement("EN COURS"));
        TypeMouvementJournal typeSortie = typeRepository.save(new TypeMouvementJournal("SORTIE", (short) -1));
        JournalMouvement journal = journalRepository.save(
                new JournalMouvement(null, "SOR-001", null, "Client", typeSortie, statutJournal));
        journalId = journal.getId();

        Role role = roleRepository.save(new Role("OPERATEUR"));
        User user = userRepository.save(new User("jean", MATRICULE, "jean@test.mg", "hash", role));
        userId = user.getId();

        rackId = rackRepository.save(new Rack("A", 3)).getId();

        // Simule l'utilisateur authentifie par le JWT.
        Jwt jwt = Jwt.withTokenValue("token")
                .header("alg", "none")
                .subject(MATRICULE)
                .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));
    }

    @AfterEach
    void nettoyerContexte() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void chaqueChangementDeStatutAjouteUneLigneDHistorique() {
        // 1. Generation : statut GENERE + premiere ligne d'historique
        PickingResponse cree = pickingService.create(new PickingCreateRequest(journalId, userId, rackId));
        assertThat(cree.statut()).isEqualTo(StatutPickingCode.GENERE);
        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE");

        // 2. Demarrage
        PickingResponse enCours = modifierStatut(cree.id(), StatutPickingCode.EN_COURS);
        assertThat(enCours.statut()).isEqualTo(StatutPickingCode.EN_COURS);
        assertThat(enCours.dateDebut()).isNotNull();
        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE", "EN_COURS");

        // 3. Fin (aucune ligne a terminer dans ce scenario)
        PickingResponse termine = modifierStatut(cree.id(), StatutPickingCode.TERMINE);
        assertThat(termine.statut()).isEqualTo(StatutPickingCode.TERMINE);
        assertThat(termine.dateFin()).isNotNull();
        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE", "EN_COURS", "TERMINE");
    }

    @Test
    void lHistoriqueConserveLUtilisateurEtLaDate() {
        PickingResponse cree = pickingService.create(new PickingCreateRequest(journalId, userId, rackId));
        modifierStatut(cree.id(), StatutPickingCode.ANNULE);

        List<HistoriquePickingStatut> lignes = historique(cree.id());

        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE", "ANNULE");
        assertThat(lignes).allSatisfy(ligne -> {
            assertThat(ligne.getUser()).isNotNull();
            assertThat(ligne.getUser().getMatricule()).isEqualTo(MATRICULE);
            assertThat(ligne.getDateChangement()).isNotNull();
        });
    }

    @Test
    void uneTransitionInterditeNEcritRienDansLHistorique() {
        PickingResponse cree = pickingService.create(new PickingCreateRequest(journalId, userId, rackId));

        // GENERE -> TERMINE est interdit (il faut passer par EN_COURS)
        assertThatThrownBy(() -> modifierStatut(cree.id(), StatutPickingCode.TERMINE))
                .isInstanceOf(ResponseStatusException.class);

        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE");
    }

    @Test
    void redemanderLeMemeStatutNAjoutePasDeDoublon() {
        PickingResponse cree = pickingService.create(new PickingCreateRequest(journalId, userId, rackId));

        modifierStatut(cree.id(), StatutPickingCode.GENERE);

        assertThat(nomsHistorique(cree.id())).containsExactly("GENERE");
    }

    @Test
    void unJournalNAccepteQuUnSeulPickingActif() {
        pickingService.create(new PickingCreateRequest(journalId, userId, rackId));

        assertThatThrownBy(() -> pickingService.create(new PickingCreateRequest(journalId, userId, rackId)))
                .isInstanceOf(ResponseStatusException.class);
    }

    private PickingResponse modifierStatut(Long pickingId, StatutPickingCode statut) {
        return pickingService.update(pickingId, new PickingUpdateRequest(userId, rackId, statut));
    }

    private List<HistoriquePickingStatut> historique(Long pickingId) {
        return historiqueRepository.findByPickingIdOrderByDateChangementAsc(pickingId);
    }

    private List<String> nomsHistorique(Long pickingId) {
        return historique(pickingId).stream()
                .map(ligne -> ligne.getStatut().getNom())
                .toList();
    }
}
