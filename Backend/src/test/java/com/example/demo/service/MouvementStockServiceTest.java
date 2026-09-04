package com.example.demo.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.demo.dto.AffectationStockRequest;
import com.example.demo.dto.CreerMouvementsStockRequest;
import com.example.demo.dto.MouvementStockResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.MouvementStock;
import com.example.demo.entity.PaletteConditionnement;
import com.example.demo.entity.StatutjournalMouvement;
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.entity.User;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.PaletteConditionnementRepository;
import com.example.demo.repository.TypeMouvementStockRepository;
import com.example.demo.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class MouvementStockServiceTest {

    @Mock
    private JournalMouvementRepository journalMouvementRepository;

    @Mock
    private DetailJournalRepository detailJournalRepository;

    @Mock
    private MouvementStockRepository mouvementStockRepository;

    @Mock
    private EmplacementRepository emplacementRepository;

    @Mock
    private PaletteConditionnementRepository paletteConditionnementRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private TypeMouvementStockRepository typeMouvementStockRepository;

    private MouvementStockService mouvementStockService;

    @BeforeEach
    void setUp() {
        mouvementStockService = new MouvementStockService(
                journalMouvementRepository,
                detailJournalRepository,
                mouvementStockRepository,
                emplacementRepository,
                paletteConditionnementRepository,
                userRepository,
                typeMouvementStockRepository);
    }

    @Test
    void placeCeQuiRentreEtEnvoieLeSurplusEnReserve() {
        Long journalId = 2L;
        Long detailId = 1L;
        Long articleId = 10L;
        Long conditionnementId = 20L;
        Long emplacementId = 100L;

        JournalMouvement journal = mock(JournalMouvement.class);
        StatutjournalMouvement statut = mock(StatutjournalMouvement.class);
        DetailJournal detail = mock(DetailJournal.class);
        Article article = mock(Article.class);
        ArticleConditionnement conditionnement = mock(ArticleConditionnement.class);
        PaletteConditionnement palette = mock(PaletteConditionnement.class);
        Emplacement emplacement = mock(Emplacement.class);
        User utilisateur = mock(User.class);
        TypeMouvementStock typeEntree = mock(TypeMouvementStock.class);

        // Le journal est valide et contient un detail de 30 conditionnements,
        // soit exactement 180 pieces avec 6 pieces par conditionnement.
        when(journal.getId()).thenReturn(journalId);
        when(journal.getReference()).thenReturn("REC-TEST-001");
        when(journal.getStatutJournalMouvement()).thenReturn(statut);
        when(statut.getNomStatut()).thenReturn("VALIDE");
        when(journal.getDetails()).thenReturn(List.of(detail));

        when(detail.getId()).thenReturn(detailId);
        when(detail.getJournalMouvement()).thenReturn(journal);
        when(detail.getArticle()).thenReturn(article);
        when(detail.getQuantiteConditionnement()).thenReturn(30);
        when(detail.getQuantite()).thenReturn(180);

        when(article.getId()).thenReturn(articleId);
        when(article.getArticleConditionnements()).thenReturn(List.of(conditionnement));
        when(conditionnement.getId()).thenReturn(conditionnementId);
        when(conditionnement.getQuantitePieceStandard()).thenReturn(6);

        // La palette ne peut recevoir que 25 conditionnements.
        when(palette.getQuantite()).thenReturn(25);
        when(emplacement.getId()).thenReturn(emplacementId);

        when(journalMouvementRepository.findById(journalId)).thenReturn(Optional.of(journal));
        when(userRepository.findByMatricule("EMP001")).thenReturn(Optional.of(utilisateur));
        when(typeMouvementStockRepository.findByNomTypeMouvement("ENTREE"))
                .thenReturn(Optional.of(typeEntree));
        when(detailJournalRepository.findById(detailId)).thenReturn(Optional.of(detail));
        when(mouvementStockRepository.existsByDetailJournalId(detailId)).thenReturn(false);
        when(emplacementRepository.findById(emplacementId)).thenReturn(Optional.of(emplacement));
        when(mouvementStockRepository.calculerNombreConditionnementsPresents(emplacementId)).thenReturn(0L);
        when(mouvementStockRepository.findArticlesPresentsByEmplacementId(emplacementId))
                .thenReturn(List.of());
        when(paletteConditionnementRepository.findByArticleConditionnementId(conditionnementId))
                .thenReturn(Optional.of(palette));

        // Simuler saveAll : Mockito retourne les mouvements que le service lui donne.
        when(mouvementStockRepository.saveAll(anyList()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        CreerMouvementsStockRequest request = new CreerMouvementsStockRequest(
                List.of(new AffectationStockRequest(detailId, emplacementId, 30)));

        List<MouvementStockResponse> reponses = mouvementStockService
                .creerEntreeStock(journalId, request, "EMP001");

        // Le service doit avoir prepare exactement deux mouvements.
        assertEquals(2, reponses.size());

        MouvementStockResponse mouvementEmplacement = reponses.get(0);
        assertEquals(emplacementId, mouvementEmplacement.emplacementId());
        assertEquals(25, mouvementEmplacement.nombreConditionnements());
        assertEquals(150, mouvementEmplacement.quantitePiecesReelle());
        assertFalse(mouvementEmplacement.enReserve());

        MouvementStockResponse mouvementReserve = reponses.get(1);
        assertNull(mouvementReserve.emplacementId());
        assertEquals(5, mouvementReserve.nombreConditionnements());
        assertEquals(30, mouvementReserve.quantitePiecesReelle());
        assertTrue(mouvementReserve.enReserve());

        // Vérifier également ce qui a réellement été transmis au repository.
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<MouvementStock>> mouvementsCaptor = ArgumentCaptor.forClass(List.class);
        verify(mouvementStockRepository).saveAll(mouvementsCaptor.capture());
        assertEquals(2, mouvementsCaptor.getValue().size());
    }
}
