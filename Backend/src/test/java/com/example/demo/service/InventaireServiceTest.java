package com.example.demo.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.LigneControleInventaireResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.ComptageInventaire;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Rack;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.repository.ComptageInventaireRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StockRepository;
import com.example.demo.repository.UserJournalMouvementRepository;

@ExtendWith(MockitoExtension.class)
class InventaireServiceTest {

    @Mock
    private JournalMouvementRepository journalMouvementRepository;

    @Mock
    private ComptageInventaireRepository comptageInventaireRepository;

    @Mock
    private StockRepository stockRepository;

    @Mock
    private UserJournalMouvementRepository userJournalMouvementRepository;

    private InventaireService inventaireService;

    @BeforeEach
    void setUp() {
        inventaireService = new InventaireService(
                journalMouvementRepository,
                comptageInventaireRepository,
                stockRepository,
                userJournalMouvementRepository);
    }

    @Test
    void retourne404LorsqueLeJournalNExistePas() {
        when(journalMouvementRepository.findById(99L)).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> inventaireService.getInventaireLignes(99L));

        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
    }

    @Test
    void retourne400LorsqueLeJournalNEstPasUnInventaire() {
        JournalMouvement journal = creerJournalAvecType("ENTREE");
        when(journalMouvementRepository.findById(1L)).thenReturn(Optional.of(journal));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> inventaireService.getInventaireLignes(1L));

        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
    }

    @Test
    void calculeLesEcartsNulNegatifEtPositif() {
        JournalMouvement journal = creerJournalAvecType("INVENTAIRE");

        ComptageInventaire comptageConforme = creerComptage(
                10L, "Coca-Cola", 100L, "A-01", "RACK-A", 1, 100);
        ComptageInventaire comptageManquant = creerComptage(
                11L, "Lait Candia", 101L, "A-02", "RACK-A", 1, 95);
        ComptageInventaire comptageSurplus = creerComptage(
                12L, "Eau Vive", 102L, "A-03", "RACK-A", 1, 108);

        when(journalMouvementRepository.findById(1L)).thenReturn(Optional.of(journal));
        when(comptageInventaireRepository.findAllByDetailJournalJournalMouvementId(1L))
                .thenReturn(List.of(comptageConforme, comptageManquant, comptageSurplus));

        when(stockRepository.trouverQuantiteTheorique(10L, 100L)).thenReturn(100);
        when(stockRepository.trouverQuantiteTheorique(11L, 101L)).thenReturn(100);
        when(stockRepository.trouverQuantiteTheorique(12L, 102L)).thenReturn(100);

        List<LigneControleInventaireResponse> lignes = inventaireService.getInventaireLignes(1L);

        assertEquals(3, lignes.size());
        assertEquals(0L, lignes.get(0).ecart());
        assertEquals(-5L, lignes.get(1).ecart());
        assertEquals(8L, lignes.get(2).ecart());

        assertEquals("Coca-Cola", lignes.get(0).nomArticle());
        assertEquals("A-01", lignes.get(0).nomEmplacement());
        assertEquals(100, lignes.get(0).quantiteTheorique());
        assertEquals(100, lignes.get(0).quanantiteComptee());

        verify(comptageInventaireRepository)
                .findAllByDetailJournalJournalMouvementId(1L);
    }

    private JournalMouvement creerJournalAvecType(String nomType) {
        JournalMouvement journal = mock(JournalMouvement.class);
        TypeMouvementJournal type = mock(TypeMouvementJournal.class);

        when(journal.getTypeMouvementJournal()).thenReturn(type);
        when(type.getNomTypeMouvement()).thenReturn(nomType);

        return journal;
    }

    private ComptageInventaire creerComptage(
            Long articleId,
            String nomArticle,
            Long emplacementId,
            String nomEmplacement,
            String nomRack,
            Integer numeroEtage,
            Integer quantiteComptee) {

        ComptageInventaire comptage = mock(ComptageInventaire.class);
        DetailJournal detail = mock(DetailJournal.class);
        Article article = mock(Article.class);
        Emplacement emplacement = mock(Emplacement.class);
        Rack rack = mock(Rack.class);

        when(comptage.getDetailJournal()).thenReturn(detail);
        when(comptage.getEmplacement()).thenReturn(emplacement);
        when(comptage.getQuantiteComptee()).thenReturn(quantiteComptee);

        when(detail.getArticle()).thenReturn(article);
        when(article.getId()).thenReturn(articleId);
        when(article.getNomArticle()).thenReturn(nomArticle);

        when(emplacement.getId()).thenReturn(emplacementId);
        when(emplacement.getNomEmplacement()).thenReturn(nomEmplacement);
        when(emplacement.getNumeroEtage()).thenReturn(numeroEtage);
        when(emplacement.getRack()).thenReturn(rack);
        when(rack.getNomRack()).thenReturn(nomRack);

        return comptage;
    }
}
