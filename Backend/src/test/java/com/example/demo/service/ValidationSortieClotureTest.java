package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDateTime;
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
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.Commande;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.LignePicking;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Prelevement;
import com.example.demo.entity.Rack;
import com.example.demo.entity.Role;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.entity.StatutLignePicking;
import com.example.demo.entity.StatutLignePickingCode;
import com.example.demo.entity.StatutPicking;
import com.example.demo.entity.StatutPickingCode;
import com.example.demo.entity.StatutPrelevement;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.CommandeRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.HistoriqueJournalMouvementStatutRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.LignePickingRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.PrelevementRepository;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.StatutLignePickingRepository;
import com.example.demo.repository.StatutPickingRepository;
import com.example.demo.repository.StatutPrelevementRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.TypeMouvementStockRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.UserRepository;

/**
 * Simule le bouton "Valider la sortie" : la validation enregistre les mouvements
 * de stock et cloture le journal. Une seconde validation est refusee.
 */
@DataJpaTest(properties = {
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Import({
        MouvementStockService.class,
        JournalStatutService.class,
        PickingService.class,
        PickingStatutService.class,
        LignePickingStatutService.class
})
class ValidationSortieClotureTest {

    private static final String MATRICULE = "M001";

    @Autowired
    private MouvementStockService mouvementStockService;

    @Autowired
    private PickingService pickingService;

    @Autowired
    private LignePickingStatutService lignePickingStatutService;

    @Autowired
    private JournalStatutService journalStatutService;

    @Autowired
    private HistoriqueJournalMouvementStatutRepository historiqueJournalRepository;

    @Autowired
    private MouvementStockRepository mouvementStockRepository;

    @Autowired
    private PrelevementRepository prelevementRepository;

    @Autowired
    private LignePickingRepository lignePickingRepository;

    @Autowired
    private PickingRepository pickingRepository;

    @Autowired
    private StatutPrelevementRepository statutPrelevementRepository;

    @Autowired
    private TypeMouvementStockRepository typeMouvementStockRepository;

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

    private Long journalId;

    @BeforeEach
    void preparerDonnees() {
        for (StatutPickingCode code : StatutPickingCode.values()) {
            statutPickingRepository.save(new StatutPicking(code.getNom()));
        }
        for (StatutLignePickingCode code : StatutLignePickingCode.values()) {
            statutLigneRepository.save(new StatutLignePicking(code.getNom()));
        }
        StatutJournalMouvement enCours = null;
        for (StatutJournalMouvementCode code : StatutJournalMouvementCode.values()) {
            StatutJournalMouvement statut = statutJournalRepository.save(new StatutJournalMouvement(code.getNom()));
            if (code == StatutJournalMouvementCode.EN_COURS) {
                enCours = statut;
            }
        }

        TypeMouvementJournal typeSortie = typeRepository.save(new TypeMouvementJournal("SORTIE", (short) -1));
        JournalMouvement journal = journalRepository.save(
                new JournalMouvement(null, "SOR-001", null, "Client", typeSortie, enCours));
        journalId = journal.getId();
        journalStatutService.enregistrerStatutInitial(journal);

        typeMouvementStockRepository.save(new TypeMouvementStock("SORTIE", (short) -1));
        StatutPrelevement statutConfirme = statutPrelevementRepository.save(new StatutPrelevement("CONFIRME"));

        Role role = roleRepository.save(new Role("OPERATEUR"));
        User user = userRepository.save(new User("jean", MATRICULE, "jean@test.mg", "hash", role));
        Rack rack = rackRepository.save(new Rack("A", 3));

        TypeProduit typeProduit = typeProduitRepository.save(new TypeProduit("Laitier"));
        TypeConditionnement typeConditionnement = typeConditionnementRepository.save(new TypeConditionnement("Carton"));
        Article article = articleRepository.save(new Article(typeProduit, "123456", "Candia", typeConditionnement));
        ArticleConditionnement conditionnement = articleConditionnementRepository.save(
                new ArticleConditionnement(article, typeConditionnement, "999", 6));
        Commande commande = new Commande(article, false, null, 10, null, true, user);
        commande.setJournalMouvement(journal);
        commande = commandeRepository.save(commande);
        Emplacement emplacement = emplacementRepository.save(new Emplacement("A-1-1", rack, 1, 1));
        DetailJournal detailJournal = detailJournalRepository.save(
                new DetailJournal(journal, article, 60, 10, null, null));

        // Simule l'utilisateur authentifie par le JWT.
        Jwt jwt = Jwt.withTokenValue("token")
                .header("alg", "none")
                .subject(MATRICULE)
                .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));

        // Un picking avec une ligne deja prelevee (1 carton = 6 pieces).
        PickingResponse picking = pickingService.create(
                new PickingCreateRequest(journalId, user.getId(), rack.getId()));
        Picking pickingEntite = pickingRepository.findById(picking.id()).orElseThrow();
        LignePicking ligne = new LignePicking(
                commande, emplacement, detailJournal, conditionnement, 1, 1, 6,
                lignePickingStatutService.trouverStatut(StatutLignePickingCode.RESERVEE));
        pickingEntite.ajouterLigne(ligne);
        LignePicking ligneSauvegardee = lignePickingRepository.save(ligne);
        lignePickingStatutService.enregistrerStatutInitial(ligneSauvegardee);
        lignePickingStatutService.changerStatut(ligneSauvegardee, StatutLignePickingCode.PRELEVEE);

        prelevementRepository.save(new Prelevement(
                commande, ligneSauvegardee, emplacement, statutConfirme, 6, user,
                LocalDateTime.now(), null, null));
    }

    @AfterEach
    void nettoyerContexte() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void validerLaSortieEnregistreLesMouvementsEtClotureLeJournal() {
        mouvementStockService.validerSortie(journalId);

        assertThat(mouvementStockRepository.findAllByTypeMouvementNomTypeMouvement("SORTIE")).hasSize(1);
        assertThat(journalRepository.findById(journalId).orElseThrow().getStatut().getNom())
                .isEqualTo("CLOTURE");
        assertThat(nomsHistorique()).containsExactly("EN COURS", "CLOTURE");
    }

    @Test
    void uneSecondeValidationEstRefuseeEtNeCreeAucunMouvement() {
        mouvementStockService.validerSortie(journalId);

        assertThatThrownBy(() -> mouvementStockService.validerSortie(journalId))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("deja cloturee");

        assertThat(mouvementStockRepository.findAllByTypeMouvementNomTypeMouvement("SORTIE")).hasSize(1);
        assertThat(nomsHistorique()).containsExactly("EN COURS", "CLOTURE");
    }

    private List<String> nomsHistorique() {
        return historiqueJournalRepository.findByJournalMouvementIdOrderByDateChangementAsc(journalId).stream()
                .map(ligne -> ligne.getStatut().getNom())
                .toList();
    }
}
