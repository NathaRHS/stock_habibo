package com.example.demo.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.DetailJournalResponse;
import com.example.demo.dto.JournalMouvementRequest;
import com.example.demo.dto.JournalMouvementResponse;
import com.example.demo.dto.ScanArticleRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Societe;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutjournalMouvement;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.SocieteRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;

@Service
@Transactional
public class JournalMouvementService {
    private static final String STATUT_EN_COURS = "EN COURS";
    private static final String STATUT_VALIDE = "VALIDE";
    private static final String STATUT_MODIFIE = "MODIFIE";

    private final JournalMouvementRepository journalRepository;
    private final TypeMouvementJournalRepository typeRepository;
    private final StatutJournalMouvementRepository statutRepository;
    private final SocieteRepository fournisseurRepository;
    private final ArticleRepository articleRepository;
    private final DetailJournalRepository detailJournalRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;

    public JournalMouvementService(
            JournalMouvementRepository journalRepository,
            TypeMouvementJournalRepository typeRepository,
            StatutJournalMouvementRepository statutRepository,
            SocieteRepository fournisseurRepository,
            ArticleRepository articleRepository, DetailJournalRepository detailJournalRepository,
            ArticleConditionnementRepository articleConditionnementRepository) {
        this.journalRepository = journalRepository;
        this.typeRepository = typeRepository;
        this.statutRepository = statutRepository;
        this.fournisseurRepository = fournisseurRepository;
        this.detailJournalRepository = detailJournalRepository;
        this.articleRepository = articleRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;

    }

    public JournalMouvementResponse create(JournalMouvementRequest request) {
        String reference = EnleverEspaceReference(request.reference());
        verifierReferenceDisponible(reference, null);
        // validerDetails(request.details());
        Long idOriginal = Long.valueOf(1);
        StatutjournalMouvement statutjournalMouvement = statutRepository.findById(idOriginal)
                .orElseThrow(() -> new RuntimeException("statut original non créé"));
        JournalMouvement journal = new JournalMouvement(
                trouverFournisseur(request.fournisseurId()),
                reference,
                normaliserFacultatif(request.urlPieceJointe()),
                normaliserFacultatif(request.nomClient()),
                trouverType(request.typeMouvementJournalId()),
                statutjournalMouvement);

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
        String reference = EnleverEspaceReference(request.reference());
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

    private Societe trouverFournisseur(Long id) {
        if (id == null) {
            return null;
        }
        return fournisseurRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Fournisseur introuvable : " + id));
    }

    private String EnleverEspaceReference(String reference) {
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

    // Transforme les JournalMOuvement en JournalMouvementResponse
    private JournalMouvementResponse versResponse(JournalMouvement journal) {
        Societe fournisseur = journal.getFournisseur();
        List<DetailJournalResponse> details = journal.getDetails().stream()
                .map(detail -> new DetailJournalResponse(
                        detail.getId(),
                        detail.getArticle().getId(),
                        detail.getArticle().getNomArticle(),
                        detail.getQuantite(), detail.getJournalMouvement().getId(),
                        detail.getJournalMouvement().getReference()))
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

    // change le statut du journal
    public JournalMouvementResponse updateStatutJournal(Long journalId, Long idStatut) {
        JournalMouvement journal = trouverJournal(journalId);
        journal.setStatutJournalMouvement(trouverStatut(idStatut));
        return versResponse(journalRepository.save(journal));
    }

    // changer le statut en "validé"
    public JournalMouvementResponse valider(Long journalId) {
        JournalMouvement journal = trouverJournal(journalId);
        verifierEnCours(journal);
        journal.setStatutJournalMouvement(trouverStatutMetier(STATUT_VALIDE));
        return versResponse(journalRepository.save(journal));
    }

    // changer le statut en "modifié"
    public JournalMouvementResponse demanderModification(Long journalId) {
        JournalMouvement journal = trouverJournal(journalId);
        verifierEnCours(journal);
        journal.setStatutJournalMouvement(trouverStatutMetier(STATUT_MODIFIE));
        return versResponse(journalRepository.save(journal));
    }

    // verifier le statut du journal actuel
    private void verifierEnCours(JournalMouvement journal) {
        String statutActuel = journal.getStatutJournalMouvement().getNomStatut();
        if (!statutActuel.equals(STATUT_EN_COURS)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "La session doit etre EN COURS pour recevoir une decision. Statut actuel : "
                            + journal.getStatutJournalMouvement().getNomStatut());
        }
    }

    //
    private StatutjournalMouvement trouverStatutMetier(String nomStatut) {
        return statutRepository.findByNomStatut(nomStatut)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Le statut " + nomStatut + " n'est pas configure"));
    }

    // transforme une liste de DetailJournal en DetailJournalResponse
    public DetailJournalResponse versResponse(DetailJournal detailJournal) {
        DetailJournalResponse detailJournalResponse = new DetailJournalResponse(detailJournal.getId(),
                detailJournal.getArticle().getId(), detailJournal.getArticle().getNomArticle(),
                detailJournal.getQuantite(), detailJournal.getJournalMouvement().getId(),
                detailJournal.getJournalMouvement().getReference());
        return detailJournalResponse;
    }

    // Prend tous les DetailsJournal pour un journal
    public List<DetailJournalResponse> getAllDetailJournalForAJournal(Long journalId) {
        return detailJournalRepository
                .findAllByJournalMouvementId(journalId)
                .stream()
                .map(this::versResponse)
                .toList();
    }

    // Prend la liste des DetailJournal
    public List<DetailJournalResponse> findAllDetailJournal() {
        return detailJournalRepository
                .findAll()
                .stream()
                .map(this::versResponse)
                .toList();

    }

    public DetailJournalResponse scanArticle(Long journalId, ScanArticleRequest request) {
        if (request.codeBarres() == null || request.codeBarres().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le code barre est obligatoire");
        }
        JournalMouvement journal = journalRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "journal introuvable"));

        if (!STATUT_EN_COURS.equals(journal.getStatutJournalMouvement().getNomStatut())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Le statut n'est plus EN COURS");
        }

        if (request.quantite() == null || request.quantite() <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La quantité doit être strictement positive");
        }
        Article article = articleRepository.findByCodeBar(request.codeBarres()).orElse(null);

        ArticleConditionnement articleConditionnement = articleConditionnementRepository
                .findByCodeBarres(request.codeBarres()).orElse(null);

        if (article == null && articleConditionnement == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Code barre inconnu");
        }
        if (articleConditionnement != null) {

            article = articleConditionnement.getArticle();
        }

        DetailJournal detailJournalRecherche = detailJournalRepository
                .findByJournalMouvementIdAndArticleId(journal.getId(), article.getId());
        if (detailJournalRecherche != null) {
            detailJournalRecherche.setQuantite(detailJournalRecherche.getQuantite() + request.quantite());
            return versResponse(detailJournalRepository.save(detailJournalRecherche));
        }
        detailJournalRecherche = detailJournalRepository
                .save(new DetailJournal(journal, article, request.quantite()));
        return versResponse(detailJournalRecherche);
    }

}
