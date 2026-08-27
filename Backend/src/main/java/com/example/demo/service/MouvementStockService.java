package com.example.demo.service;

import java.time.LocalDateTime;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.management.RuntimeErrorException;

/*
Recuperer la liste Affectations


Affectations[
    {
        idDetailJournal:1
        idEmplacement:1
        Quantite:125
        
        },
        {
        idDetailJournal:1
        idEmplacement:1
        Quantite:12

    },
]
-verifier somme  produit detail == produit dans la base -> LEVER UNE EXCEPTION{tel produit tsy mifanintsy}
-verifier d'abord si le journal a une statut validee
- verifier le detail produit
    - verifier le type conditionnement
        - verifier paletteconfiguration
    -verifier si emplacement choisi ne contient pas d'autres articles ou ne dépasse pas la quantité prévu si il ne contient pas d'autres articles(mettre dans la reserve)

    - faire ça pour toutes les articles 


    -Prendre le detailJournal et ses mouvements
        Si article existe : verifier si même type que dans DetailJournal sinon LEVER EXCEPTION.
        Si vide : insérer.



        /*
1. Récupérer la liste des affectations.

2. Vérifier :
   - requête non vide ;
   - identifiants présents ;
   - quantités positives ;
   - aucune répétition detailJournal + emplacement.

3. Récupérer le journal.
   - vérifier qu’il existe ;
   - vérifier qu’il est VALIDE.

4. Regrouper les affectations par DetailJournal.

5. Pour chaque DetailJournal :
   - vérifier qu’il existe ;
   - vérifier qu’il appartient au journal ;
   - récupérer son Article ;
   - récupérer son unique ArticleConditionnement ;
   - récupérer sa PaletteConditionnement ;
   - additionner les quantités affectées ;
   - vérifier que la somme correspond à
     detailJournal.quantiteConditionnement.

6. Pour chaque affectation
   - récupérer l’Emplacement ;
   - récupérer les mouvements existants de cet emplacement ;
   - calculer son stock net ;

   Si l’emplacement est vide :
       calculer la quantité pouvant entrer.

   Si l’emplacement contient le même Article :
       calculer sa capacité restante.

   Si l’emplacement contient un autre Article :
       ne rien placer dans cet emplacement ;
       envoyer toute la quantité en réserve.

   Si la quantité dépasse la capacité restante :
       placer ce qui rentre ;
       envoyer le surplus en réserve.

7. Construire les MouvementStock normaux et ceux de réserve.

8. Enregistrer tous les mouvements avec saveAll.
*/

import org.springframework.stereotype.Service;

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
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.entity.User;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.PaletteConditionnementRepository;
import com.example.demo.repository.TypeMouvementStockRepository;
import com.example.demo.repository.UserRepository;

import jakarta.transaction.Transactional;

@Service
public class MouvementStockService {

    private final JournalMouvementRepository journalMouvementRepository;
    private final PaletteConditionnementRepository palelConditionnementRepository;
    private final DetailJournalRepository detailJournalRepository;
    private final EmplacementRepository emplacementRepository;
    private final MouvementStockRepository mouvementStockRepository;
    private final UserRepository userRepository;
    private final TypeMouvementStockRepository typeMouvementStockRepository;

    private static final String STATUT_VALIDE_JOURNAL = "VALIDE";
    private static final String TYPE_MOUVEMENT_ENTREE = "ENTREE";

    public MouvementStockService(JournalMouvementRepository journalMouvementRepository,
            DetailJournalRepository detailJournalRepository, MouvementStockRepository mouvementStockRepository,
            EmplacementRepository emplacementRepository,
            PaletteConditionnementRepository palelConditionnementRepository,
            UserRepository userRepository,
            TypeMouvementStockRepository typeMouvementStockRepository) {
        this.journalMouvementRepository = journalMouvementRepository;
        this.palelConditionnementRepository = palelConditionnementRepository;
        this.detailJournalRepository = detailJournalRepository;
        this.emplacementRepository = emplacementRepository;
        this.mouvementStockRepository = mouvementStockRepository;
        this.userRepository = userRepository;
        this.typeMouvementStockRepository = typeMouvementStockRepository;
    }


    @Transactional
    public List<MouvementStockResponse> creerEntreeStock(Long journalId, CreerMouvementsStockRequest request,
            String matricule) {

        if (request == null || request.affectations() == null || request.affectations().isEmpty()) {
            throw new RuntimeException("La liste des affectations fournie est vide");
        }

        List<AffectationStockRequest> listeDesAffectations = request.affectations();
        // verifier si le journal existe

        JournalMouvement journalMouvement = journalMouvementRepository.findById(journalId)
                .orElseThrow(() -> new RuntimeException("journal introuvable"));
        // vérifier si le statut du journal est déjà valide
        if (!journalMouvement.getStatutJournalMouvement().getNomStatut().equals(STATUT_VALIDE_JOURNAL)) {
            throw new RuntimeException("Le statut du journal n'est pas encore VALIDE");
        }

        // Recuperer l'utilisateur qui valide l'entree depuis le matricule du JWT.
        User utilisateur = userRepository.findByMatricule(matricule)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));

        // Rechercher le type par son nom et non avec un identifiant fixe.
        TypeMouvementStock typeMouvementEntree = typeMouvementStockRepository
                .findByNomTypeMouvement(TYPE_MOUVEMENT_ENTREE)
                .orElseThrow(() -> new RuntimeException("Le type de mouvement ENTREE est introuvable"));

        // regroupement liste affectation
        Map<Long, Integer> affectation = new LinkedHashMap<>();
        for (AffectationStockRequest affectationStockRequest : listeDesAffectations) {
            // Verifier les champs obligatoires de chaque ligne du JSON.
            if (affectationStockRequest == null
                    || affectationStockRequest.detailJournalId() == null
                    || affectationStockRequest.emplacementId() == null
                    || affectationStockRequest.nombreConditionnements() == null
                    || affectationStockRequest.nombreConditionnements() <= 0) {
                throw new RuntimeException("Une affectation est incomplete ou possede une quantite invalide");
            }

            Integer quantite = affectationStockRequest.nombreConditionnements();
            DetailJournal detailJournal = detailJournalRepository.findById(affectationStockRequest.detailJournalId())
                    .orElseThrow(() -> new RuntimeException("detail journal inexistant"));
            if (detailJournal.getJournalMouvement() == null
                    || !journalMouvement.getId().equals(detailJournal.getJournalMouvement().getId())) {
                throw new RuntimeException("Le detail journal n'est pas dans le journal ");
            }
            // regarder si l'id est déjà là si oui on ajoute la quantité si non on insère
            if (!affectation.containsKey(affectationStockRequest.detailJournalId())) {
                affectation.put(affectationStockRequest.detailJournalId(), quantite);
            } else {
                Integer ancienneQuantite = affectation.get(affectationStockRequest.detailJournalId());
                affectation.put(affectationStockRequest.detailJournalId(), ancienneQuantite + quantite);
            }

        }
        // verifier si la quantité du detail == quantité affectés
        for (Map.Entry<Long, Integer> entree : affectation.entrySet()) {
            Long detailJournalId = entree.getKey();
            Integer quantiteAffectee = entree.getValue();

            DetailJournal correspondant = detailJournalRepository.findById(detailJournalId)
                    .orElseThrow(() -> new RuntimeException("le detail journal n'existe pas"));

            if (!correspondant.getQuantiteConditionnement().equals(quantiteAffectee)) {
                throw new RuntimeException("Les quantités du détails" + detailJournalId + " ne s'alligne pas");
            }

            // rechercher le DetailJournal
            // comparer quantiteAffectee avec getQuantiteConditionnement()
        }

        // Verifier qu'aucun detail du journal n'a ete oublie dans le JSON et
        // qu'aucune entree n'a deja ete creee pour ce detail.
        for (DetailJournal detailJournal : journalMouvement.getDetails()) {
            if (!affectation.containsKey(detailJournal.getId())) {
                throw new RuntimeException("Aucune affectation pour le detail " + detailJournal.getId());
            }
            if (mouvementStockRepository.existsByDetailJournalId(detailJournal.getId())) {
                throw new RuntimeException("Des mouvements existent deja pour le detail " + detailJournal.getId());
            }
        }

        // Les mouvements sont construits en memoire et seront enregistres ensemble
        // seulement apres la validation de toutes les affectations.
        List<MouvementStock> mouvementsAPreparer = new ArrayList<>();

        // Conserver les pieces exactes restant a repartir pour chaque detail. Cette
        // map evite de transformer une derniere boite partielle en boite pleine.
        Map<Long, Integer> piecesRestantesParDetail = new LinkedHashMap<>();
        for (DetailJournal detailJournal : journalMouvement.getDetails()) {
            piecesRestantesParDetail.put(detailJournal.getId(), detailJournal.getQuantite());
        }

        // Tenir compte des lignes precedentes du meme JSON lorsqu'elles visent le
        // meme emplacement, meme si elles ne sont pas encore en base.
        Map<Long, Long> quantitesPlanifieesParEmplacement = new LinkedHashMap<>();
        Map<Long, Long> articlePlanifieParEmplacement = new LinkedHashMap<>();
        LocalDateTime dateMouvement = LocalDateTime.now();

        for (AffectationStockRequest affectationTsirairay : listeDesAffectations) {
            Long detailJournalId = affectationTsirairay.detailJournalId();
            Long emplacementId = affectationTsirairay.emplacementId();
            Integer quantiteAPlacer = affectationTsirairay.nombreConditionnements();

            DetailJournal detailJournal = detailJournalRepository
                    .findById(detailJournalId)
                    .orElseThrow(() -> new RuntimeException("Détail journal introuvable"));

            Emplacement emplacement = emplacementRepository
                    .findById(emplacementId)
                    .orElseThrow(() -> new RuntimeException("Emplacement introuvable"));

            long stockActuelle = mouvementStockRepository.calculerNombreConditionnementsPresents(emplacementId);
            stockActuelle += quantitesPlanifieesParEmplacement.getOrDefault(emplacementId, 0L);

            // AJOUT : recuperer la configuration de palette depuis l'article a placer.
            ArticleConditionnement articleConditionnementAPlacer = detailJournal.getArticle()
                    .getArticleConditionnements().get(0);
            PaletteConditionnement paletteConditionnement = palelConditionnementRepository
                    .findByArticleConditionnementId(articleConditionnementAPlacer.getId())
                    .orElseThrow(() -> new RuntimeException(
                            "il n'y a pas de palette conditionnement pour ce conditionnement"));

            // AJOUT : capacite maximale de l'emplacement en conditionnements.
            Integer capacitePalette = paletteConditionnement.getQuantite();

            List<Article> ListearticlesPresentSurEmplacementEnCours = mouvementStockRepository
                    .findArticlesPresentsByEmplacementId(emplacementId);

            // Verifier les articles deja en base et ceux deja prepares dans ce JSON.
            boolean autreArticlePresent = false;
            for (Article articlePresent : ListearticlesPresentSurEmplacementEnCours) {
                if (!detailJournal.getArticle().getId().equals(articlePresent.getId())) {
                    autreArticlePresent = true;
                }
            }
            Long articlePlanifieId = articlePlanifieParEmplacement.get(emplacementId);
            if (articlePlanifieId != null && !detailJournal.getArticle().getId().equals(articlePlanifieId)) {
                autreArticlePresent = true;
            }

            // AJOUT : quantites calculees pour l'emplacement choisi et la reserve.
            long quantiteQuiPeutRentrer;
            long quantiteEnReserve;

            if (autreArticlePresent) {
                // Un article different occupe deja la palette : toute la quantite
                // reste en reserve sans emplacement physique.
                quantiteQuiPeutRentrer = 0;
                quantiteEnReserve = quantiteAPlacer;
            } else {
                // Palette vide ou contenant le meme article : utiliser uniquement la
                // capacite qui reste disponible.
                long placeRestante = Math.max(capacitePalette - stockActuelle, 0);
                quantiteQuiPeutRentrer = Math.min(quantiteAPlacer, placeRestante);
                quantiteEnReserve = quantiteAPlacer - quantiteQuiPeutRentrer;
            }

            // Creer le mouvement vers l'emplacement pour la partie qui peut entrer.
            if (quantiteQuiPeutRentrer > 0) {
                int nombreConditionnements = Math.toIntExact(quantiteQuiPeutRentrer);
                int capaciteEnPieces = Math.multiplyExact(
                        nombreConditionnements,
                        articleConditionnementAPlacer.getQuantitePieceStandard());
                int piecesRestantes = piecesRestantesParDetail.get(detailJournalId);
                int piecesAffectees = Math.min(piecesRestantes, capaciteEnPieces);
                piecesRestantesParDetail.put(detailJournalId, piecesRestantes - piecesAffectees);

                mouvementsAPreparer.add(new MouvementStock(
                        typeMouvementEntree,
                        emplacement,
                        utilisateur,
                        nombreConditionnements,
                        articleConditionnementAPlacer,
                        piecesAffectees,
                        dateMouvement,
                        "Entree en stock du journal " + journalMouvement.getReference(),
                        detailJournal,
                        false));

                // Memoriser cette quantite pour les lignes suivantes du meme JSON.
                quantitesPlanifieesParEmplacement.merge(
                        emplacementId,
                        quantiteQuiPeutRentrer,
                        Long::sum);
                articlePlanifieParEmplacement.put(emplacementId, detailJournal.getArticle().getId());
            }

            // Creer un second mouvement sans emplacement pour le surplus en reserve.
            if (quantiteEnReserve > 0) {
                int nombreConditionnements = Math.toIntExact(quantiteEnReserve);
                int capaciteEnPieces = Math.multiplyExact(
                        nombreConditionnements,
                        articleConditionnementAPlacer.getQuantitePieceStandard());
                int piecesRestantes = piecesRestantesParDetail.get(detailJournalId);
                int piecesAffectees = Math.min(piecesRestantes, capaciteEnPieces);
                piecesRestantesParDetail.put(detailJournalId, piecesRestantes - piecesAffectees);

                mouvementsAPreparer.add(new MouvementStock(
                        typeMouvementEntree,
                        null,
                        utilisateur,
                        nombreConditionnements,
                        articleConditionnementAPlacer,
                        piecesAffectees,
                        dateMouvement,
                        "Entree en reserve du journal " + journalMouvement.getReference(),
                        detailJournal,
                        true));
            }
        }

        // Verifier que la quantite reelle de chaque detail a ete entierement repartie.
        for (Map.Entry<Long, Integer> entree : piecesRestantesParDetail.entrySet()) {
            if (entree.getValue() != 0) {
                throw new RuntimeException("Toutes les pieces du detail " + entree.getKey()
                        + " n'ont pas ete reparties");
            }
        }

        // Un seul enregistrement pour tous les mouvements. La transaction annule tout
        // si l'une des insertions echoue.
        return mouvementStockRepository.saveAll(mouvementsAPreparer)
                .stream()
                .map(this::versResponse)
                .toList();
    }

    // Consultation de tous les mouvements existants.
    public List<MouvementStockResponse> findAll() {
        return mouvementStockRepository.findAll()
                .stream()
                .map(this::versResponse)
                .toList();
    }

    // Consultation des mouvements d'entree sans supposer que leur identifiant vaut 1.
    public List<MouvementStockResponse> getAllEntry() {
        return mouvementStockRepository
                .findAllByTypeMouvementNomTypeMouvement(TYPE_MOUVEMENT_ENTREE)
                .stream()
                .map(this::versResponse)
                .toList();
    }

    // Un mouvement de reserve n'a pas d'emplacement : son emplacementId est null.
    private MouvementStockResponse versResponse(MouvementStock mouvementStock) {
        Long emplacementId = mouvementStock.getEmplacement() == null
                ? null
                : mouvementStock.getEmplacement().getId();

        return new MouvementStockResponse(
                mouvementStock.getId(),
                mouvementStock.getDetailJournal().getId(),
                emplacementId,
                mouvementStock.getNombreConditionnements(),
                mouvementStock.getQuantitePiecesReelle(),
                mouvementStock.getDateMouvement(),
                mouvementStock.isEnReserve());
    }

}
