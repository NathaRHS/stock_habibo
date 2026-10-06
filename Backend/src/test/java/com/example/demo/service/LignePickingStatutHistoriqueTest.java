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
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.Commande;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.HistoriqueLignePickingStatut;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.LignePicking;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Rack;
import com.example.demo.entity.Role;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutLignePicking;
import com.example.demo.entity.StatutLignePickingCode;
import com.example.demo.entity.StatutPicking;
import com.example.demo.entity.StatutPickingCode;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.CommandeRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.HistoriqueLignePickingStatutRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.LignePickingRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.StatutLignePickingRepository;
import com.example.demo.repository.StatutPickingRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.UserRepository;

/**
 * Simule la vie des lignes d'un picking sur une base H2 en memoire :
 * reservation, prelevement, annulation du picking. Verifie que chaque
 * changement de statut d'une ligne ajoute une ligne d'historique.
 */
@DataJpaTest(properties = {
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Import({ PickingService.class, PickingStatutService.class, LignePickingStatutService.class })
class LignePickingStatutHistoriqueTest {

    private static final String MATRICULE = "M001";

    @Autowired
    private PickingService pickingService;

    @Autowired
    private LignePickingStatutService lignePickingStatutService;

    @Autowired
    private HistoriqueLignePickingStatutRepository historiqueRepository;

    @Autowired
    private LignePickingRepository lignePickingRepository;

    @Autowired
    private PickingRepository pickingRepository;

    @Autowired
    private StatutLignePickingRepository statutLigneRepository;

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

    @Autowired
    private TypeProduitRepository typeProduitRepository;

    @Autowired
    private TypeConditionnementRepository typeConditionnementRepository;

    @Autowired
    private ArticleRepository articleRepository;

    @Autowired
    private ArticleConditionnementRepository articleConditionnementRepository;

    @Autowired
    private CommandeRepository commandeRepository;

    @Autowired
    private EmplacementRepository emplacementRepository;

    @Autowired
    private DetailJournalRepository detailJournalRepository;

    private Long userId;
    private Long rackId;
    private Long pickingId;

    private User user;
    private Rack rack;
    private JournalMouvement journal;
    private Article article;
    private ArticleConditionnement conditionnement;
    private Commande commande;
    private Emplacement emplacement;
    private DetailJournal detailJournal;

    @BeforeEach
    void preparerDonnees() {
        for (StatutPickingCode code : StatutPickingCode.values()) {
            statutPickingRepository.save(new StatutPicking(code.getNom()));
        }
        for (StatutLignePickingCode code : StatutLignePickingCode.values()) {
            statutLigneRepository.save(new StatutLignePicking(code.getNom()));
        }

        StatutJournalMouvement statutJournal = statutJournalRepository.save(new StatutJournalMouvement("EN COURS"));
        TypeMouvementJournal typeSortie = typeRepository.save(new TypeMouvementJournal("SORTIE", (short) -1));
        journal = journalRepository.save(
                new JournalMouvement(null, "SOR-001", null, "Client", typeSortie, statutJournal));

        Role role = roleRepository.save(new Role("OPERATEUR"));
        user = userRepository.save(new User("jean", MATRICULE, "jean@test.mg", "hash", role));
        userId = user.getId();

        rack = rackRepository.save(new Rack("A", 3));
        rackId = rack.getId();

        TypeProduit typeProduit = typeProduitRepository.save(new TypeProduit("Laitier"));
        TypeConditionnement typeConditionnement = typeConditionnementRepository.save(new TypeConditionnement("Carton"));
        article = articleRepository.save(new Article(typeProduit, "123456", "Candia", typeConditionnement));
        conditionnement = articleConditionnementRepository.save(
                new ArticleConditionnement(article, typeConditionnement, "999", 6));
        commande = new Commande(article, false, null, 10, null, true, user);
        commande.setJournalMouvement(journal);
        commande = commandeRepository.save(commande);
        emplacement = emplacementRepository.save(new Emplacement("A-1-1", rack, 1, 1));
        detailJournal = detailJournalRepository.save(new DetailJournal(journal, article, 60, 10, null, null));

        // Simule l'utilisateur authentifie par le JWT.
        Jwt jwt = Jwt.withTokenValue("token")
                .header("alg", "none")
                .subject(MATRICULE)
                .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));

        PickingResponse picking = pickingService.create(new PickingCreateRequest(journal.getId(), userId, rackId));
        pickingId = picking.id();
    }

    @AfterEach
    void nettoyerContexte() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void chaqueChangementDeStatutDeLaLigneAjouteUneLigneDHistorique() {
        LignePicking ligne = creerLigne(1);
        assertThat(nomsHistorique(ligne)).containsExactly("RESERVEE");

        lignePickingStatutService.changerStatut(ligne, StatutLignePickingCode.EN_COURS);
        assertThat(nomsHistorique(ligne)).containsExactly("RESERVEE", "EN_COURS");

        lignePickingStatutService.changerStatut(ligne, StatutLignePickingCode.PRELEVEE);
        assertThat(nomsHistorique(ligne)).containsExactly("RESERVEE", "EN_COURS", "PRELEVEE");
        assertThat(ligne.getStatutCode()).isEqualTo(StatutLignePickingCode.PRELEVEE);
    }

    @Test
    void lHistoriqueConserveLUtilisateurEtLaDate() {
        LignePicking ligne = creerLigne(1);
        lignePickingStatutService.changerStatut(ligne, StatutLignePickingCode.EN_COURS);

        List<HistoriqueLignePickingStatut> lignes = historique(ligne);

        assertThat(lignes).hasSize(2);
        assertThat(lignes).allSatisfy(entree -> {
            assertThat(entree.getUser()).isNotNull();
            assertThat(entree.getUser().getMatricule()).isEqualTo(MATRICULE);
            assertThat(entree.getDateChangement()).isNotNull();
        });
    }

    @Test
    void redemanderLeMemeStatutNAjoutePasDeDoublon() {
        LignePicking ligne = creerLigne(1);

        lignePickingStatutService.changerStatut(ligne, StatutLignePickingCode.RESERVEE);

        assertThat(nomsHistorique(ligne)).containsExactly("RESERVEE");
    }

    @Test
    void annulerLePickingAnnuleSesLignesActivesEtGardeLesLignesPrelevees() {
        LignePicking reservee = creerLigne(1);
        LignePicking prelevee = creerLigne(2);
        lignePickingStatutService.changerStatut(prelevee, StatutLignePickingCode.PRELEVEE);

        pickingService.update(pickingId, new PickingUpdateRequest(userId, rackId, StatutPickingCode.ANNULE));

        assertThat(reservee.getStatutCode()).isEqualTo(StatutLignePickingCode.ANNULEE);
        assertThat(nomsHistorique(reservee)).containsExactly("RESERVEE", "ANNULEE");

        assertThat(prelevee.getStatutCode()).isEqualTo(StatutLignePickingCode.PRELEVEE);
        assertThat(nomsHistorique(prelevee)).containsExactly("RESERVEE", "PRELEVEE");
    }

    @Test
    void terminerUnPickingAvecUneLigneReserveeEstRefuse() {
        LignePicking ligne = creerLigne(1);
        pickingService.update(pickingId, new PickingUpdateRequest(userId, rackId, StatutPickingCode.EN_COURS));

        assertThatThrownBy(() -> pickingService.update(
                pickingId, new PickingUpdateRequest(userId, rackId, StatutPickingCode.TERMINE)))
                .isInstanceOf(ResponseStatusException.class);

        assertThat(nomsHistorique(ligne)).containsExactly("RESERVEE");
    }

    private LignePicking creerLigne(int ordre) {
        Picking picking = pickingRepository.findById(pickingId).orElseThrow();
        LignePicking ligne = new LignePicking(
                commande,
                emplacement,
                detailJournal,
                conditionnement,
                ordre,
                1,
                6,
                lignePickingStatutService.trouverStatut(StatutLignePickingCode.RESERVEE));
        picking.ajouterLigne(ligne);
        LignePicking sauvegardee = lignePickingRepository.save(ligne);
        lignePickingStatutService.enregistrerStatutInitial(sauvegardee);
        return sauvegardee;
    }

    private List<HistoriqueLignePickingStatut> historique(LignePicking ligne) {
        return historiqueRepository.findByLignePickingIdOrderByDateChangementAsc(ligne.getId());
    }

    private List<String> nomsHistorique(LignePicking ligne) {
        return historique(ligne).stream()
                .map(entree -> entree.getStatut().getNom())
                .toList();
    }
}
