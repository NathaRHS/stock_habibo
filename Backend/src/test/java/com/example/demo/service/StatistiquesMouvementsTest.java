package com.example.demo.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.stock.PointMensuelResponse;
import com.example.demo.dto.stock.SyntheseMouvementsResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.MouvementStock;
import com.example.demo.entity.Role;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.TypeMouvementStockRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.UserRepository;

/**
 * Les totaux de l'accueil sont calcules par la base. Ces tests fixent les regles de
 * l'ancien calcul du navigateur, qui doivent rester les memes : type ENTREE ou SORTIE par
 * son nom, pieces reelles, periode [debut, fin[, reserve comprise.
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
class StatistiquesMouvementsTest {

    private static final LocalDate JOUR = LocalDate.of(2026, 3, 10);

    @Autowired
    private MouvementStockService service;
    @Autowired
    private MouvementStockRepository mouvementStockRepository;
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
    private TypeProduitRepository typeProduitRepository;
    @Autowired
    private TypeConditionnementRepository typeConditionnementRepository;
    @Autowired
    private ArticleRepository articleRepository;
    @Autowired
    private ArticleConditionnementRepository conditionnementRepository;
    @Autowired
    private JournalMouvementRepository journalRepository;
    @Autowired
    private DetailJournalRepository detailRepository;

    private TypeMouvementStock entree;
    private TypeMouvementStock sortie;
    private User utilisateur;
    private ArticleConditionnement conditionnement;
    private DetailJournal detail;

    @BeforeEach
    void preparerDonnees() {
        StatutJournalMouvement statut = statutRepository.save(new StatutJournalMouvement("VALIDE"));
        TypeMouvementJournal typeJournal = typeJournalRepository.save(new TypeMouvementJournal("ENTREE", (short) 1));
        entree = typeStockRepository.save(new TypeMouvementStock("ENTREE", (short) 1));
        sortie = typeStockRepository.save(new TypeMouvementStock("SORTIE", (short) -1));

        Role role = roleRepository.save(new Role("ADMIN"));
        utilisateur = userRepository.save(new User("admin", "M001", "admin@test.mg", "hash", role));

        TypeProduit typeProduit = typeProduitRepository.save(new TypeProduit("Laitier"));
        TypeConditionnement typeConditionnement = typeConditionnementRepository.save(new TypeConditionnement("Carton"));
        Article article = articleRepository.save(new Article(typeProduit, "123456", "Candia", typeConditionnement));
        conditionnement = conditionnementRepository.save(new ArticleConditionnement(article, typeConditionnement, "999", 6));

        JournalMouvement journal = journalRepository.save(
                new JournalMouvement(null, "REC-001", null, "Fournisseur", typeJournal, statut));
        detail = detailRepository.save(new DetailJournal(journal, article, 60, 10, null, null));
    }

    private void mouvement(TypeMouvementStock type, int pieces, LocalDateTime date, boolean enReserve) {
        mouvementStockRepository.save(new MouvementStock(
                type, null, utilisateur, 1, conditionnement, pieces, date, "test", detail, enReserve));
    }

    @Test
    void lesTotauxDeLaPeriodeSeparentEntreesEtSorties() {
        // Periode courante : [10 mars, 11 mars[
        mouvement(entree, 60, JOUR.atTime(8, 0), false);
        mouvement(entree, 40, JOUR.atTime(23, 59, 59), false);
        mouvement(sortie, 25, JOUR.atTime(12, 0), false);
        mouvement(entree, 7, JOUR.atTime(9, 0), true); // la reserve est comptee, comme avant
        mouvement(entree, 10, JOUR.plusDays(1).atStartOfDay(), false); // fin exclue : hors periode

        // Periode precedente : [9 mars, 10 mars[
        mouvement(entree, 30, JOUR.minusDays(1).atStartOfDay(), false); // debut inclus
        mouvement(sortie, 5, JOUR.minusDays(1).atTime(23, 0), false);
        mouvement(entree, 999, JOUR.minusDays(2).atTime(23, 59), false); // avant la precedente

        SyntheseMouvementsResponse synthese = service.synthese(JOUR, JOUR.plusDays(1));

        assertThat(synthese.courante().entrees()).isEqualTo(107L);
        assertThat(synthese.courante().sorties()).isEqualTo(25L);
        assertThat(synthese.courante().nombreMouvements()).isEqualTo(4L);
        assertThat(synthese.precedente().entrees()).isEqualTo(30L);
        assertThat(synthese.precedente().sorties()).isEqualTo(5L);
        assertThat(synthese.precedente().nombreMouvements()).isEqualTo(2L);
    }

    @Test
    void laPeriodePrecedenteADeLaMemeDureeQueLaPeriodeDemandee() {
        // Periode de 3 jours : la precedente est [7 mars, 10 mars[
        mouvement(entree, 11, JOUR.minusDays(3).atStartOfDay(), false);
        mouvement(entree, 22, JOUR.minusDays(1).atTime(12, 0), false);
        mouvement(entree, 500, JOUR.minusDays(4).atTime(23, 0), false); // trop ancien

        SyntheseMouvementsResponse synthese = service.synthese(JOUR, JOUR.plusDays(3));

        assertThat(synthese.precedente().entrees()).isEqualTo(33L);
        assertThat(synthese.precedente().nombreMouvements()).isEqualTo(2L);
        assertThat(synthese.courante().entrees()).isZero();
    }

    @Test
    void sansMouvementLesTotauxValentZero() {
        SyntheseMouvementsResponse synthese = service.synthese(JOUR, JOUR.plusDays(1));

        assertThat(synthese.courante().entrees()).isZero();
        assertThat(synthese.courante().sorties()).isZero();
        assertThat(synthese.courante().nombreMouvements()).isZero();
        assertThat(synthese.precedente().nombreMouvements()).isZero();
    }

    @Test
    void lesPeriodesInvalidesSontRefusees() {
        assertThat(codeDe(() -> service.synthese(JOUR, JOUR))).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(codeDe(() -> service.synthese(JOUR, JOUR.minusDays(1)))).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(codeDe(() -> service.synthese(JOUR, JOUR.plusDays(367)))).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void laSerieMensuelleGroupeParMoisEtCompleteLesMoisSansMouvement() {
        mouvement(entree, 10, LocalDateTime.of(2026, 1, 15, 10, 0), false);
        mouvement(sortie, 4, LocalDateTime.of(2026, 1, 20, 10, 0), false);
        mouvement(entree, 50, LocalDateTime.of(2026, 3, 1, 0, 0), false);
        mouvement(entree, 7, LocalDateTime.of(2025, 12, 31, 23, 59), false); // annee precedente
        mouvement(entree, 8, LocalDateTime.of(2027, 1, 1, 0, 0), false); // annee suivante

        List<PointMensuelResponse> serie = service.serieMensuelle(2026);

        assertThat(serie).hasSize(12);
        assertThat(serie.get(0)).isEqualTo(new PointMensuelResponse(1, 10L, 4L));
        assertThat(serie.get(1)).isEqualTo(new PointMensuelResponse(2, 0L, 0L));
        assertThat(serie.get(2)).isEqualTo(new PointMensuelResponse(3, 50L, 0L));
        assertThat(serie.subList(3, 12)).allSatisfy(point -> {
            assertThat(point.entrees()).isZero();
            assertThat(point.sorties()).isZero();
        });
    }

    @Test
    void uneAnneeInvalideEstRefusee() {
        assertThat(codeDe(() -> service.serieMensuelle(1999))).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(codeDe(() -> service.serieMensuelle(2101))).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    private HttpStatus codeDe(Runnable appel) {
        ResponseStatusException erreur = (ResponseStatusException) catchThrowable(appel);
        return HttpStatus.valueOf(erreur.getStatusCode().value());
    }

    private static Throwable catchThrowable(Runnable appel) {
        try {
            appel.run();
        } catch (Throwable throwable) {
            return throwable;
        }
        throw new AssertionError("Une erreur etait attendue");
    }
}
