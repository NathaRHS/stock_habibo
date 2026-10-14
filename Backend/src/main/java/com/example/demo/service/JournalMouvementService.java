package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.journal.DetailJournalResponse;
import com.example.demo.dto.inventaire.ComptageInventaireResponse;
import com.example.demo.dto.journal.JournalMouvementRequest;
import com.example.demo.dto.journal.JournalMouvementResponse;
import com.example.demo.dto.journal.ScanArticleRequest;
import com.example.demo.dto.inventaire.ScanInventaireRequest;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.ComptageInventaire;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.Societe;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.entity.TypeEvenementUser;
import com.example.demo.entity.TypeMouvementJournal;
import com.example.demo.entity.User;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.ComptageInventaireRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.SocieteRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StatutJournalMouvementRepository;
import com.example.demo.repository.TypeMouvementJournalRepository;
import com.example.demo.repository.UserRepository;

@Service
@Transactional
public class JournalMouvementService {
    private final JournalMouvementRepository journalRepository;
    private final TypeMouvementJournalRepository typeRepository;
    private final StatutJournalMouvementRepository statutRepository;
    private final SocieteRepository fournisseurRepository;
    private final UserJournalMouvementService userJournalMouvementService;
    private final ArticleRepository articleRepository;
    private final DetailJournalRepository detailJournalRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;
    private final EmplacementRepository emplacementRepository;
    private final ComptageInventaireRepository comptageInventaireRepository;
    private final UserRepository userRepository;
    private final JournalStatutService journalStatutService;
    private final JournalUserService journalUserService;

    public JournalMouvementService(
            JournalMouvementRepository journalRepository,
            TypeMouvementJournalRepository typeRepository,
            StatutJournalMouvementRepository statutRepository,
            SocieteRepository fournisseurRepository,
            UserJournalMouvementService userJournalMouvementService,
            ArticleRepository articleRepository, DetailJournalRepository detailJournalRepository,
            ArticleConditionnementRepository articleConditionnementRepository,
            EmplacementRepository emplacementRepository,
            ComptageInventaireRepository comptageInventaireRepository, UserRepository userRepository,
            JournalStatutService journalStatutService,
            JournalUserService journalUserService) {
        this.journalUserService = journalUserService;
        this.journalRepository = journalRepository;
        this.typeRepository = typeRepository;
        this.userJournalMouvementService = userJournalMouvementService;
        this.statutRepository = statutRepository;
        this.fournisseurRepository = fournisseurRepository;
        this.detailJournalRepository = detailJournalRepository;
        this.articleRepository = articleRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
        this.emplacementRepository = emplacementRepository;
        this.comptageInventaireRepository = comptageInventaireRepository;
        this.userRepository = userRepository;
        this.journalStatutService = journalStatutService;

    }

    public JournalMouvementResponse create(JournalMouvementRequest request) {
        String reference = EnleverEspaceReference(request.reference());
        verifierReferenceDisponible(reference, null);
        // validerDetails(request.details());
        StatutJournalMouvement statut = journalStatutService.trouverStatut(StatutJournalMouvementCode.EN_COURS);
        JournalMouvement journal = new JournalMouvement(
                trouverFournisseur(request.fournisseurId()),
                reference,
                normaliserFacultatif(request.urlPieceJointe()),
                normaliserFacultatif(request.nomClient()),
                trouverType(request.typeMouvementJournalId()),
                statut);

        // remplacerDetails(journal, request.details());
        if (!journal.getTypeMouvementJournal().getNomTypeMouvement().equals("INVENTAIRE")
                && journalRepository.compterInventairesEnCours() > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Un inventaire est en cours : impossible de créer une entrée ou une sortie");
        }

        JournalMouvement journalSauvegarde = journalRepository.save(journal);
        journalStatutService.enregistrerStatutInitial(journalSauvegarde);

        journalUserService.enregistrer(
                TypeEvenementUser.JOURNAL_CREE,
                CibleEvenement.JOURNAL,
                journalSauvegarde.getId(),
                reference + " (" + journalSauvegarde.getTypeMouvementJournal().getNomTypeMouvement() + ")");

        return versResponse(journalSauvegarde);
    }

    public boolean checkInventaireEnCours() {
        return journalRepository.compterInventairesEnCours() > 0;
    }

    @Transactional(readOnly = true)
    public List<JournalMouvementResponse> findAll() {
        return journalRepository.findAll().stream().map(this::versResponse).toList();
    }

    @Transactional
    public JournalMouvementResponse findAllByParticipantsId(Long id) {
        return versResponse(journalRepository.findByParticipantsId(id));
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
        journalStatutService.changerStatut(
                journal,
                convertirStatut(trouverStatut(request.statutJournalMouvementId())));
        // remplacerDetails(journal, request.details());

        JournalMouvementResponse reponse = versResponse(journalRepository.save(journal));

        journalUserService.enregistrer(
                TypeEvenementUser.JOURNAL_MODIFIE,
                CibleEvenement.JOURNAL,
                id,
                reference);

        return reponse;
    }

    public void delete(Long id) {
        JournalMouvement journal = trouverJournal(id);
        // Decrit avant la suppression : apres, il n'y aurait plus rien a lire.
        String description = journal.getReference() + " ("
                + journal.getTypeMouvementJournal().getNomTypeMouvement() + ", statut "
                + journal.getStatut().getNom() + ")";

        journalRepository.delete(journal);

        journalUserService.enregistrer(
                TypeEvenementUser.JOURNAL_SUPPRIME,
                CibleEvenement.JOURNAL,
                id,
                description);
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

    private StatutJournalMouvement trouverStatut(Long id) {
        if (id == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "statutJournalMouvementId est obligatoire");
        }
        StatutJournalMouvement statut = statutRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Statut de journal introuvable : " + id));
        verifierStatutDeJournal(statut);
        return statut;
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
                        detail.getJournalMouvement().getReference(),
                        detail.getQuantiteConditionnement(),
                        detail.getDlc(),
                        detail.getDlv()))
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
                journal.getStatut().getId(),
                journal.getStatut().getNom(),
                details);
    }

    // change le statut du journal
    public JournalMouvementResponse updateStatutJournal(Long journalId, Long idStatut) {
        JournalMouvement journal = trouverJournal(journalId);
        journalStatutService.changerStatut(journal, convertirStatut(trouverStatut(idStatut)));
        return versResponse(journalRepository.save(journal));
    }

    // changer lxe statut en "validé"
    public JournalMouvementResponse valider(Long journalId) {
        JournalMouvement journal = trouverJournal(journalId);
        verifierStatutActuel(journal, StatutJournalMouvementCode.EN_ATTENTE);
        journalStatutService.changerStatut(journal, StatutJournalMouvementCode.VALIDE);
        return versResponse(journalRepository.save(journal));
    }

    // changer le statut en "modifié"
    public JournalMouvementResponse demanderModification(Long journalId) {
        JournalMouvement journal = trouverJournal(journalId);
        verifierStatutActuel(journal, StatutJournalMouvementCode.EN_ATTENTE);
        journalStatutService.changerStatut(journal, StatutJournalMouvementCode.MODIFIE);
        return versResponse(journalRepository.save(journal));
    }

    private void verifierStatutActuel(
            JournalMouvement journal,
            StatutJournalMouvementCode... statutsAutorises) {
        StatutJournalMouvementCode statutActuel = convertirStatut(journal.getStatut());
        if (!List.of(statutsAutorises).contains(statutActuel)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Transition interdite depuis le statut " + statutActuel.getNom());
        }
    }

    private StatutJournalMouvementCode convertirStatut(StatutJournalMouvement statut) {
        try {
            return StatutJournalMouvementCode.depuisNom(statut.getNom());
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage());
        }
    }

    private void verifierStatutDeJournal(StatutJournalMouvement statut) {
        if (!StatutJournalMouvementCode.accepte(statut.getNom())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le statut " + statut.getNom() + " n'est pas autorise pour un journal de mouvement");
        }
    }

    // transforme une liste de DetailJournal en DetailJournalResponse
    public DetailJournalResponse versResponse(DetailJournal detailJournal) {
        DetailJournalResponse detailJournalResponse = new DetailJournalResponse(detailJournal.getId(),
                detailJournal.getArticle().getId(), detailJournal.getArticle().getNomArticle(),
                detailJournal.getQuantite(), detailJournal.getJournalMouvement().getId(),
                detailJournal.getJournalMouvement().getReference(),
                detailJournal.getQuantiteConditionnement(),
                detailJournal.getDlc(),
                detailJournal.getDlv());
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

    // scan article
    public DetailJournalResponse scanArticle(Long journalId, ScanArticleRequest request, String matricule) {
        if (request.codeBarres() == null || request.codeBarres().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le code barre est obligatoire");
        }
        JournalMouvement journal = journalRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "journal introuvable"));

        verifierStatutActuel(
                journal,
                StatutJournalMouvementCode.EN_COURS,
                StatutJournalMouvementCode.MODIFIE);
        if (request.dlc() == null || request.dlv() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La DLC et la DLV sont obligatoires pour une reception");
        }
        if (request.dlv().isAfter(request.dlc())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La DLV ne peut pas etre posterieure a la DLC");
        }
        Integer conditionnementsSaisis = request.quantiteConditionnement();
        Integer piecesSaisies = request.quantite();

        if (conditionnementsSaisis == null && piecesSaisies == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Renseignez la quantité de conditionnement, la quantité réelle, ou les deux");
        }
        if (conditionnementsSaisis != null && conditionnementsSaisis <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité de conditionnement doit être strictement positive");
        }
        if (piecesSaisies != null && piecesSaisies <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité réelle doit être strictement positive");
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

        if (conditionnementsSaisis != null && articleConditionnement == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité de conditionnement nécessite un code-barres de conditionnement");
        }

        articleConditionnement = resoudreConditionnementStandard(articleConditionnement, article);
        int quantitePieceStandard = articleConditionnement.getQuantitePieceStandard();

        // Conditionnements et pieces reelles : une boite peut etre incomplete.
        int conditionnements;
        int pieces;
        if (conditionnementsSaisis != null && piecesSaisies != null) {
            int maximum = convertirEnQuantitePiece(conditionnementsSaisis, quantitePieceStandard);
            int minimum = maximum - quantitePieceStandard;
            if (piecesSaisies <= minimum || piecesSaisies > maximum) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        conditionnementsSaisis + " conditionnement(s) de " + quantitePieceStandard
                                + " pièces : le nombre de pièces doit être entre "
                                + (minimum + 1) + " et " + maximum
                                + " (au plus une boîte incomplète)");
            }
            conditionnements = conditionnementsSaisis;
            pieces = piecesSaisies;
        } else if (conditionnementsSaisis != null) {
            conditionnements = conditionnementsSaisis;
            pieces = convertirEnQuantitePiece(conditionnementsSaisis, quantitePieceStandard);
        } else {
            pieces = piecesSaisies;
            conditionnements = (pieces + quantitePieceStandard - 1) / quantitePieceStandard;
        }

        userJournalMouvementService.ajouterParticipant(journalId, matricule);

        DetailJournal detailExistant = detailJournalRepository
                .findByJournalMouvementIdAndArticleId(journal.getId(), article.getId());
        if (detailExistant != null
                && (!request.dlc().equals(detailExistant.getDlc())
                        || !request.dlv().equals(detailExistant.getDlv()))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cet article existe deja dans la reception avec une autre DLC ou DLV");
        }

        detailJournalRepository.ajouterOuIncrementerPrecis(
                journalId,
                article.getId(),
                pieces,
                conditionnements,
                request.dlc(),
                request.dlv());

        DetailJournal detailJournalRecherche = detailJournalRepository
                .findByJournalMouvementIdAndArticleId(journal.getId(), article.getId());

        if (detailJournalRecherche == null) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Le résultat du scan n'a pas pu être récupéré");
        }

        return versResponse(detailJournalRecherche);

    }

    // Enregistre un comptage d'inventaire pour un article et un emplacement.
    public ComptageInventaireResponse scanArticleInventaire(
            Long journalId,
            ScanInventaireRequest request,
            String matricule) {

        if (request.codeBarres() == null || request.codeBarres().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Le code-barres est obligatoire");
        }
        if (request.emplacementId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'emplacement est obligatoire");
        }
        Integer conditionnementsSaisis = request.quantiteConditionnement();

        if (conditionnementsSaisis == null
                && (request.quantite() == null || request.quantite() <= 0)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantite doit etre strictement positive");
        }
        if (conditionnementsSaisis != null && conditionnementsSaisis <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité de conditionnement doit être strictement positive");
        }
        if (conditionnementsSaisis != null && request.quantite() != null
                && request.quantite() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité réelle doit être strictement positive");
        }

        JournalMouvement journal = journalRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Journal introuvable"));

        String typeJournal = journal.getTypeMouvementJournal().getNomTypeMouvement();
        if (!"INVENTAIRE".equalsIgnoreCase(typeJournal.trim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le journal n'est pas de type INVENTAIRE");
        }
        verifierStatutActuel(
                journal,
                StatutJournalMouvementCode.EN_COURS,
                StatutJournalMouvementCode.MODIFIE);

        Emplacement emplacement = emplacementRepository.findById(request.emplacementId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Emplacement " + request.emplacementId() + " introuvable"));

        Article article = articleRepository.findByCodeBar(request.codeBarres()).orElse(null);
        ArticleConditionnement conditionnementScanne = articleConditionnementRepository
                .findByCodeBarres(request.codeBarres())
                .orElse(null);

        if (article == null && conditionnementScanne == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Code-barres inconnu");
        }
        if (conditionnementScanne != null) {
            article = conditionnementScanne.getArticle();
        }

        if (conditionnementsSaisis != null && conditionnementScanne == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "La quantité de conditionnement nécessite un code-barres de conditionnement");
        }

        // Le conditionnement standard permet de convertir le comptage en pieces.
        ArticleConditionnement conditionnementStandard = resoudreConditionnementStandard(conditionnementScanne,
                article);
        int quantitePieceStandard = conditionnementStandard.getQuantitePieceStandard();

        int conditionnements;
        int quantiteReelle;
        if (conditionnementsSaisis != null) {
            conditionnements = conditionnementsSaisis;
            int maximum = convertirEnQuantitePiece(conditionnementsSaisis, quantitePieceStandard);
            if (request.quantite() != null) {
                if (request.quantite() > Integer.MAX_VALUE) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                            "La quantite saisie est trop grande");
                }
                int pieces = request.quantite().intValue();
                int minimum = maximum - quantitePieceStandard;
                if (pieces <= minimum || pieces > maximum) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                            conditionnementsSaisis + " conditionnement(s) de " + quantitePieceStandard
                                    + " pièces : le nombre de pièces doit être entre "
                                    + (minimum + 1) + " et " + maximum
                                    + " (au plus une boîte incomplète)");
                }
                quantiteReelle = pieces;
            } else {
                quantiteReelle = maximum;
            }
        } else {
            // Ancien comportement : le sens de `quantite` depend du code scanne.
            if (request.quantite() > Integer.MAX_VALUE) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "La quantite saisie est trop grande");
            }
            int quantiteSaisie = request.quantite().intValue();
            quantiteReelle = conditionnementScanne == null
                    ? quantiteSaisie
                    : convertirEnQuantitePiece(quantiteSaisie, quantitePieceStandard);
            conditionnements = (quantiteReelle + quantitePieceStandard - 1) / quantitePieceStandard;
        }

        userJournalMouvementService.ajouterParticipant(journalId, matricule);

        User user = userRepository.findByMatricule(matricule)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "le participant est introuvable"));

        // DetailJournal conserve le total compte pour l'article dans la session.
        detailJournalRepository.ajouterOuIncrementerPrecis(
                journalId,
                article.getId(),
                quantiteReelle,
                conditionnements,
                null,
                null);

        DetailJournal detailJournal = detailJournalRepository
                .findByJournalMouvementIdAndArticleId(journalId, article.getId());
        if (detailJournal == null) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Le detail du comptage n'a pas pu etre recupere");
        }

        // ComptageInventaire conserve la quantite comptee dans cet emplacement.
        LocalDateTime dateComptage = LocalDateTime.now();
        comptageInventaireRepository.ajouterOuIncrementer(
                detailJournal.getId(),
                emplacement.getId(),
                quantiteReelle,

                dateComptage);

        ComptageInventaire comptage = comptageInventaireRepository
                .findByDetailJournalIdAndEmplacementId(detailJournal.getId(), emplacement.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                        "Le comptage d'inventaire n'a pas pu etre recupere"));
        comptage.setUser(user);
        return versComptageInventaireResponse(comptage);
    }

    // Résout le conditionnement standard d'un article (celui scanné, sinon le
    // premier configuré)
    // et vérifie que sa quantité par pièce est valide.
    private ArticleConditionnement resoudreConditionnementStandard(
            ArticleConditionnement conditionnementScanne, Article article) {
        ArticleConditionnement conditionnement = conditionnementScanne;
        if (conditionnement == null) {
            conditionnement = articleConditionnementRepository
                    .findFirstByArticleIdOrderByIdAsc(article.getId())
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.BAD_REQUEST,
                            "Aucun conditionnement n'est configure pour cet article"));
        }
        Integer quantitePieceStandard = conditionnement.getQuantitePieceStandard();
        if (quantitePieceStandard == null || quantitePieceStandard <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "La quantite standard du conditionnement est invalide");
        }
        return conditionnement;
    }

    // Convertit une quantité de conditionnements en quantité de pièces, en
    // détectant le dépassement.
    private int convertirEnQuantitePiece(int quantiteConditionnements, int quantitePieceStandard) {
        try {
            return Math.multiplyExact(quantiteConditionnements, quantitePieceStandard);
        } catch (ArithmeticException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La quantité calculée est trop grande");
        }
    }

    private ComptageInventaireResponse versComptageInventaireResponse(ComptageInventaire comptage) {
        DetailJournal detail = comptage.getDetailJournal();
        return new ComptageInventaireResponse(
                comptage.getId(),
                detail.getId(),
                detail.getArticle().getId(),
                detail.getArticle().getNomArticle(),
                comptage.getUser().getUsername(),
                comptage.getEmplacement().getId(),
                comptage.getEmplacement().getNomEmplacement(),
                comptage.getQuantiteComptee(),
                comptage.getDateComptage());
    }
}

/*
 * 
 * 
 * code-barres
 * → ArticleConditionnement exact
 * → DetailJournal
 * → MouvementStock
 * 
 * 
 * 
 * Mais c'est ce que je te dis , un article normalement a qu'un seul
 * conditionnemennt , donc ce qu'on fait c'est prendre l'article et fetch limit
 * 1 même si y a qu'un de base article\_conditionnement
 */
