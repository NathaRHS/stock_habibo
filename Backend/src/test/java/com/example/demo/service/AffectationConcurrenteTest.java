package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.stock.AffectationStockRequest;
import com.example.demo.dto.stock.CreerMouvementsStockRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.PaletteConditionnement;
import com.example.demo.entity.Rack;
import com.example.demo.entity.Role;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.PaletteConditionnementRepository;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.TypeMouvementStockRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.UserRepository;

/**
 * Deux administrateurs affectent en meme temps (vrais threads, vraies transactions).
 * Les donnees sont enregistrees pour de bon : pas de transaction autour du test.
 */
@DataJpaTest(properties = {
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Import({
        MouvementStockService.class,
        JournalStatutService.class,
        JournalUserService.class,
        NotificationService.class,
        LignePickingStatutService.class,
        BonResteService.class
})
@Transactional(propagation = Propagation.NOT_SUPPORTED)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class AffectationConcurrenteTest {

    private static final String MATRICULE = "M001";

    @Autowired
    private MouvementStockService mouvementStockService;
    @Autowired
    private MouvementStockRepository mouvementStockRepository;
    @Autowired
    private JournalMouvementRepository journalRepository;
    @Autowired
    private StatutJournalMouvementRepository statutRepository;
    @Autowired
    private TypeMouvementJournalRepository typeJournalRepository;
    @Autowired
    private TypeMouvementStockRepository typeStockRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RackRepository rackRepository;
    @Autowired
    private EmplacementRepository emplacementRepository;
    @Autowired
    private TypeProduitRepository typeProduitRepository;
    @Autowired
    private TypeConditionnementRepository typeConditionnementRepository;
    @Autowired
    private ArticleRepository articleRepository;
    @Autowired
    private ArticleConditionnementRepository conditionnementRepository;
    @Autowired
    private PaletteConditionnementRepository paletteRepository;
    @Autowired
    private DetailJournalRepository detailRepository;

    private StatutJournalMouvement valide;
    private TypeMouvementJournal typeEntree;
    private Article article;
    private Emplacement emplacement;

    @BeforeEach
    void preparerDonnees() {
        for (StatutJournalMouvementCode code : StatutJournalMouvementCode.values()) {
            StatutJournalMouvement statut = statutRepository.save(new StatutJournalMouvement(code.getNom()));
            if (code == StatutJournalMouvementCode.VALIDE) {
                valide = statut;
            }
        }
        typeEntree = typeJournalRepository.save(new TypeMouvementJournal("ENTREE", (short) 1));
        typeStockRepository.save(new TypeMouvementStock("ENTREE", (short) 1));

        Role role = roleRepository.save(new Role("ADMIN"));
        userRepository.save(new User("admin", MATRICULE, "admin@test.mg", "hash", role));

        Rack rack = rackRepository.save(new Rack("A", 3));
        emplacement = emplacementRepository.save(new Emplacement("A-1-1", rack, 1, 1));

        TypeProduit typeProduit = typeProduitRepository.save(new TypeProduit("Laitier"));
        TypeConditionnement typeConditionnement = typeConditionnementRepository.save(new TypeConditionnement("Carton"));
        article = articleRepository.save(new Article(typeProduit, "123456", "Candia", typeConditionnement));
        conditionnementRepository.save(new ArticleConditionnement(article, typeConditionnement, "999", 6));
    }

    // Une palette de 'capacite' conditionnements pour l'article.
    private void configurerPalette(int capacite) {
        ArticleConditionnement conditionnement = conditionnementRepository.findAll().get(0);
        paletteRepository.save(new PaletteConditionnement(conditionnement, capacite));
    }

    // Journal d'entree VALIDE avec un detail de 'conditionnements' cartons de 6 pieces.
    private DetailJournal creerJournalValide(String reference, int conditionnements) {
        JournalMouvement journal = journalRepository.save(
                new JournalMouvement(null, reference, null, "Fournisseur", typeEntree, valide));
        return detailRepository.save(
                new DetailJournal(journal, article, conditionnements * 6, conditionnements, null, null));
    }

    private static CreerMouvementsStockRequest affecter(DetailJournal detail, Long emplacementId, int conditionnements) {
        return new CreerMouvementsStockRequest(
                List.of(new AffectationStockRequest(detail.getId(), emplacementId, conditionnements)));
    }

    // Lance toutes les affectations ensemble (meme top de depart) et rend leurs resultats.
    private List<Object> lancerEnMemeTemps(List<Long> journalIds, List<CreerMouvementsStockRequest> requetes)
            throws Exception {
        int nombre = requetes.size();
        ExecutorService executeur = Executors.newFixedThreadPool(nombre);
        CountDownLatch pret = new CountDownLatch(nombre);
        CountDownLatch depart = new CountDownLatch(1);
        List<Future<Object>> futurs = new ArrayList<>();
        for (int i = 0; i < nombre; i++) {
            Long journalId = journalIds.get(i);
            CreerMouvementsStockRequest requete = requetes.get(i);
            futurs.add(executeur.submit(() -> {
                pret.countDown();
                depart.await();
                try {
                    return mouvementStockService.creerEntreeStock(journalId, requete, MATRICULE);
                } catch (Exception exception) {
                    return exception;
                }
            }));
        }
        pret.await();
        depart.countDown();

        List<Object> resultats = new ArrayList<>();
        for (Future<Object> futur : futurs) {
            resultats.add(futur.get(30, TimeUnit.SECONDS));
        }
        executeur.shutdown();
        return resultats;
    }

    @Test
    void lAffectationDuMemeJournalNEstFaiteQuUneFois() throws Exception {
        configurerPalette(50);
        DetailJournal detail = creerJournalValide("REC-001", 80);
        Long journalId = detail.getJournalMouvement().getId();

        // 4 envois simultanes de la meme affectation (double clic, deux admins...).
        List<Object> resultats = lancerEnMemeTemps(
                List.of(journalId, journalId, journalId, journalId),
                List.of(affecter(detail, emplacement.getId(), 80),
                        affecter(detail, emplacement.getId(), 80),
                        affecter(detail, emplacement.getId(), 80),
                        affecter(detail, emplacement.getId(), 80)));

        List<Object> refus = resultats.stream().filter(Exception.class::isInstance).toList();
        assertThat(resultats.size() - refus.size()).as("affectations reussies").isEqualTo(1);
        assertThat(refus).allSatisfy(exception -> {
            assertThat(exception).isInstanceOf(ResponseStatusException.class);
            assertThat(((ResponseStatusException) exception).getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        });

        // 50 en emplacement + 30 en reserve = 2 mouvements, pas 8.
        assertThat(mouvementStockRepository.findAll()).hasSize(2);
        assertThat(journalRepository.findById(journalId).orElseThrow().getStatut().getNom()).isEqualTo("AFFECTEE");
    }

    @Test
    void deuxJournauxVersLeMemeEmplacementNeDepassentPasSaCapacite() throws Exception {
        configurerPalette(100);
        DetailJournal premier = creerJournalValide("REC-001", 80);
        DetailJournal second = creerJournalValide("REC-002", 80);

        List<Object> resultats = lancerEnMemeTemps(
                List.of(premier.getJournalMouvement().getId(), second.getJournalMouvement().getId()),
                List.of(affecter(premier, emplacement.getId(), 80),
                        affecter(second, emplacement.getId(), 80)));

        assertThat(resultats).noneMatch(Exception.class::isInstance);

        // 160 conditionnements arrives pour 100 de place : 100 rangent, 60 vont en reserve.
        assertThat(mouvementStockRepository.calculerNombreConditionnementsPresents(emplacement.getId()))
                .isEqualTo(100L);
        int enReserve = mouvementStockRepository.findAll().stream()
                .filter(mouvement -> mouvement.isEnReserve())
                .mapToInt(mouvement -> mouvement.getNombreConditionnements())
                .sum();
        assertThat(enReserve).isEqualTo(60);
    }
}
