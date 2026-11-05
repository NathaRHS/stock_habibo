package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;
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

import com.example.demo.dto.journal.JournalMouvementRequest;
import com.example.demo.dto.journal.JournalMouvementResponse;
import com.example.demo.dto.journal.ScanArticleRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.HistoriqueJournalMouvementStatut;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.Role;
import com.example.demo.entity.Societe;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.HistoriqueJournalMouvementStatutRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.SocieteRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.UserRepository;

/**
 * Simule la vie d'un journal de mouvement sur une base H2 en memoire :
 * creation, participation, fin de participation, validation.
 * Verifie que chaque changement de statut ajoute une ligne d'historique.
 */
@DataJpaTest(properties = {
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Import({ JournalMouvementService.class, UserJournalMouvementService.class, JournalStatutService.class,
        JournalUserService.class, NotificationService.class })
class JournalStatutHistoriqueTest {

    private static final String MATRICULE = "M001";

    @Autowired
    private JournalMouvementService journalService;

    @Autowired
    private UserJournalMouvementService participationService;

    @Autowired
    private HistoriqueJournalMouvementStatutRepository historiqueRepository;

    @Autowired
    private StatutJournalMouvementRepository statutRepository;

    @Autowired
    private TypeMouvementJournalRepository typeRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SocieteRepository societeRepository;

    @Autowired
    private ArticleRepository articleRepository;

    @Autowired
    private TypeProduitRepository typeProduitRepository;

    @Autowired
    private TypeConditionnementRepository typeConditionnementRepository;

    private Long typeEntreeId;
    private Long fournisseurId;

    @BeforeEach
    void preparerDonnees() {
        for (StatutJournalMouvementCode code : StatutJournalMouvementCode.values()) {
            statutRepository.save(new StatutJournalMouvement(code.getNom()));
        }

        typeEntreeId = typeRepository.save(new TypeMouvementJournal("ENTREE", (short) 1)).getId();
        // Une entree vient toujours d'un fournisseur.
        fournisseurId = societeRepository.save(new Societe("HB")).getId();

        Role role = roleRepository.save(new Role("OPERATEUR"));
        userRepository.save(new User("jean", MATRICULE, "jean@test.mg", "hash", role));

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
        // 1. Creation : statut EN COURS + premiere ligne d'historique
        Long journalId = creerJournal("REF-001");
        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS");

        // 2. Un participant rejoint la session : pas de changement de statut
        participationService.ajouterParticipant(journalId, MATRICULE);
        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS");

        // 3. Le dernier participant termine : passage automatique EN ATTENTE
        participationService.terminerParticipation(journalId, MATRICULE);
        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS", "EN ATTENTE");

        // 4. Validation : passage a VALIDE
        JournalMouvementResponse valide = journalService.valider(journalId);
        assertThat(valide.statut()).isEqualTo("VALIDE");
        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS", "EN ATTENTE", "VALIDE");
    }

    @Test
    void lHistoriqueConserveLUtilisateurEtUneDateOrdonnee() {
        Long journalId = creerJournal("REF-002");
        participationService.ajouterParticipant(journalId, MATRICULE);
        participationService.terminerParticipation(journalId, MATRICULE);
        journalService.valider(journalId);

        List<HistoriqueJournalMouvementStatut> lignes = historique(journalId);

        assertThat(lignes).hasSize(3);
        assertThat(lignes).allSatisfy(ligne -> {
            assertThat(ligne.getUser()).isNotNull();
            assertThat(ligne.getUser().getMatricule()).isEqualTo(MATRICULE);
            assertThat(ligne.getDateChangement()).isNotNull();
        });
        assertThat(lignes.get(0).getDateChangement())
                .isBeforeOrEqualTo(lignes.get(2).getDateChangement());
    }

    @Test
    void uneTransitionInterditeNEcritRienDansLHistorique() {
        Long journalId = creerJournal("REF-003");

        // Valider un journal encore EN COURS est interdit (il faut EN ATTENTE)
        assertThatThrownBy(() -> journalService.valider(journalId))
                .isInstanceOf(ResponseStatusException.class);

        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS");
    }

    @Test
    void redemanderLeMemeStatutNAjoutePasDeDoublon() {
        Long journalId = creerJournal("REF-004");
        Long statutEnCoursId = statutRepository.findByNom("EN COURS").orElseThrow().getId();

        journalService.updateStatutJournal(journalId, statutEnCoursId);

        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS");
    }

    @Test
    void uneEntreeSansFournisseurEstRefusee() {
        JournalMouvementRequest sansFournisseur = new JournalMouvementRequest(
                "REF-005", null, null, null, typeEntreeId, null);

        assertThatThrownBy(() -> journalService.create(sansFournisseur))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("fournisseur");
    }

    @Test
    void uneEntreeAvecFournisseurEstAcceptee() {
        Long journalId = creerJournal("REF-006");

        assertThat(nomsHistorique(journalId)).containsExactly("EN COURS");
    }

    @Test
    void scannerUnArticleDUneAutreSocieteEstRefuse() {
        Long journalId = creerJournal("REF-007"); // fournisseur HB
        Societe hh = societeRepository.save(new Societe("HH"));
        creerArticle("ART-HH", hh);

        assertThatThrownBy(() -> journalService.scanArticle(journalId, scan("ART-HH"), MATRICULE))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("HH")
                .hasMessageContaining("HB");
    }

    @Test
    void scannerUnArticleSansSocieteEstRefuse() {
        Long journalId = creerJournal("REF-008");
        creerArticle("ART-SANS", null);

        assertThatThrownBy(() -> journalService.scanArticle(journalId, scan("ART-SANS"), MATRICULE))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("pas de société");
    }

    private void creerArticle(String codeBar, Societe societe) {
        Article article = new Article(
                typeProduitRepository.save(new TypeProduit("Hygiène-" + codeBar)),
                codeBar,
                "Produit " + codeBar,
                typeConditionnementRepository.save(new TypeConditionnement("Carton-" + codeBar)));
        article.setSociete(societe);
        articleRepository.save(article);
    }

    private ScanArticleRequest scan(String codeBarres) {
        return new ScanArticleRequest(codeBarres, null, 1, LocalDate.now().plusDays(60), LocalDate.now().plusDays(30));
    }

    private Long creerJournal(String reference) {
        JournalMouvementRequest request = new JournalMouvementRequest(
                reference, null, null, fournisseurId, typeEntreeId, null);
        return journalService.create(request).id();
    }

    private List<HistoriqueJournalMouvementStatut> historique(Long journalId) {
        return historiqueRepository.findByJournalMouvementIdOrderByDateChangementAsc(journalId);
    }

    private List<String> nomsHistorique(Long journalId) {
        return historique(journalId).stream()
                .map(ligne -> ligne.getStatut().getNom())
                .toList();
    }
}
