package com.example.demo.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.DetailJournalRequest;
import com.example.demo.dto.DetailJournalResponse;
import com.example.demo.dto.JournalMouvementRequest;
import com.example.demo.dto.JournalMouvementResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Fournisseur;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutjournalMouvement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.FournisseurRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;

@Service
@Transactional
public class JournalMouvementService {
    private final JournalMouvementRepository journalRepository;
    private final TypeMouvementJournalRepository typeRepository;
    private final StatutJournalMouvementRepository statutRepository;
    private final FournisseurRepository fournisseurRepository;
    private final ArticleRepository articleRepository;

    public JournalMouvementService(
            JournalMouvementRepository journalRepository,
            TypeMouvementJournalRepository typeRepository,
            StatutJournalMouvementRepository statutRepository,
            FournisseurRepository fournisseurRepository,
            ArticleRepository articleRepository) {
        this.journalRepository = journalRepository;
        this.typeRepository = typeRepository;
        this.statutRepository = statutRepository;
        this.fournisseurRepository = fournisseurRepository;
        this.articleRepository = articleRepository;
    }

    public JournalMouvementResponse create(JournalMouvementRequest request) {
        String reference = normaliserReference(request.reference());
        verifierReferenceDisponible(reference, null);
        // validerDetails(request.details());

        JournalMouvement journal = new JournalMouvement(
                trouverFournisseur(request.fournisseurId()),
                reference,
                normaliserFacultatif(request.urlPieceJointe()),
                normaliserFacultatif(request.nomClient()),
                trouverType(request.typeMouvementJournalId()),
                trouverStatut(request.statutJournalMouvementId()));

        // remplacerDetails(journal, request.details());
        return versResponse(journalRepository.save(journal));
    }

    @Transactional(readOnly = true)
    public List<JournalMouvementResponse> findAll() {
        return journalRepository.findAll().stream().map(this::versResponse).toList();
    }

    @Transactional(readOnly = true)
    public JournalMouvementResponse findById(Long id) {
        return versResponse(trouverJournal(id));
    }

    public JournalMouvementResponse update(Long id, JournalMouvementRequest request) {
        JournalMouvement journal = trouverJournal(id);
        String reference = normaliserReference(request.reference());
        verifierReferenceDisponible(reference, id);
        // validerDetails(request.details());

        journal.setReference(reference);
        journal.setUrlPieceJointe(normaliserFacultatif(request.urlPieceJointe()));
        journal.setNomClient(normaliserFacultatif(request.nomClient()));
        journal.setFournisseur(trouverFournisseur(request.fournisseurId()));
        journal.setTypeMouvementJournal(trouverType(request.typeMouvementJournalId()));
        journal.setStatutJournalMouvement(trouverStatut(request.statutJournalMouvementId()));
        // remplacerDetails(journal, request.details());

        return versResponse(journalRepository.save(journal));
    }

    public void delete(Long id) {
        journalRepository.delete(trouverJournal(id));
    }

    private void remplacerDetails(JournalMouvement journal, List<DetailJournalRequest> requests) {
        journal.supprimerTousLesDetails();
        for (DetailJournalRequest request : requests) {
            Article article = articleRepository.findById(request.articleId())
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Article introuvable : " + request.articleId()));
            journal.ajouterDetail(new DetailJournal(journal, article, request.quantite()));
        }
    }

    private void validerDetails(List<DetailJournalRequest> details) {
        if (details == null || details.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le journal doit contenir au moins un detail");
        }
        for (DetailJournalRequest detail : details) {
            if (detail == null || detail.articleId() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "articleId est obligatoire");
            }
            if (detail.quantite() == null || detail.quantite() <= 0) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "La quantite doit etre strictement positive");
            }
        }
    }

    private JournalMouvement trouverJournal(Long id) {
        return journalRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Journal de mouvement introuvable : " + id));
    }

    private TypeMouvementJournal trouverType(Long id) {
        if (id == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "typeMouvementJournalId est obligatoire");
        }
        return typeRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Type de mouvement journal introuvable : " + id));
    }

    private StatutjournalMouvement trouverStatut(Long id) {
        if (id == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "statutJournalMouvementId est obligatoire");
        }
        return statutRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Statut de journal introuvable : " + id));
    }

    private Fournisseur trouverFournisseur(Long id) {
        if (id == null) {
            return null;
        }
        return fournisseurRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Fournisseur introuvable : " + id));
    }

    private String normaliserReference(String reference) {
        if (reference == null || reference.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La reference est obligatoire");
        }
        return reference.trim();
    }

    private String normaliserFacultatif(String valeur) {
        return valeur == null || valeur.isBlank() ? null : valeur.trim();
    }

    private void verifierReferenceDisponible(String reference, Long idExclu) {
        journalRepository.findByReference(reference)
                .filter(journal -> idExclu == null || !journal.getId().equals(idExclu))
                .ifPresent(journal -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT, "Cette reference existe deja : " + reference);
                });
    }

    private JournalMouvementResponse versResponse(JournalMouvement journal) {
        Fournisseur fournisseur = journal.getFournisseur();
        List<DetailJournalResponse> details = journal.getDetails().stream()
                .map(detail -> new DetailJournalResponse(
                        detail.getId(),
                        detail.getArticle().getId(),
                        detail.getArticle().getNomArticle(),
                        detail.getQuantite()))
                .toList();

        return new JournalMouvementResponse(
                journal.getId(),
                journal.getReference(),
                journal.getUrlPieceJointe(),
                journal.getNomClient(),
                fournisseur == null ? null : fournisseur.getId(),
                fournisseur == null ? null : fournisseur.getNomSociete(),
                journal.getTypeMouvementJournal().getId(),
                journal.getTypeMouvementJournal().getNomTypeMouvement(),
                journal.getTypeMouvementJournal().getSens(),
                journal.getStatutJournalMouvement().getId(),
                journal.getStatutJournalMouvement().getNomStatut(),
                details);
    }
}
