package com.example.demo.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.dto.journal.BonResteResponse;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.Commande;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Prelevement;
import com.example.demo.entity.StatutJournalMouvement;
import com.example.demo.entity.StatutJournalMouvementCode;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.CommandeRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.PrelevementRepository;

/**
 * Bon de reste : quand une sortie n'a pas pu etre servie en entier (produit
 * absent, stock insuffisant), le manque devient une NOUVELLE sortie, comme si le
 * client avait redemande ce qui lui manque.
 *
 * Tout est exprime en conditionnements, comme la quantite demandee d'une
 * commande. Le reste est CALCULE (demande - ce qui a ete reellement preleve),
 * jamais stocke : il ne peut donc pas diverger des prelevements.
 */
@Service
public class BonResteService {

    private final PrelevementRepository prelevementRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;
    private final CommandeRepository commandeRepository;
    private final JournalMouvementRepository journalMouvementRepository;
    private final JournalStatutService journalStatutService;

    public BonResteService(
            PrelevementRepository prelevementRepository,
            ArticleConditionnementRepository articleConditionnementRepository,
            CommandeRepository commandeRepository,
            JournalMouvementRepository journalMouvementRepository,
            JournalStatutService journalStatutService) {
        this.prelevementRepository = prelevementRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
        this.commandeRepository = commandeRepository;
        this.journalMouvementRepository = journalMouvementRepository;
        this.journalStatutService = journalStatutService;
    }

    /**
     * Manque de chaque commande du journal, en conditionnements.
     * Les commandes entierement servies n'apparaissent pas dans le resultat.
     */
    @Transactional(readOnly = true)
    public Map<Commande, Integer> calculerRestes(JournalMouvement journal) {
        Map<Commande, Integer> restes = new LinkedHashMap<>();

        List<Commande> commandes = journal.getCommandes() == null
                ? new ArrayList<>()
                : journal.getCommandes();

        for (Commande commande : commandes) {
            if (commande.getQuantiteDemandee() == null || commande.getQuantiteDemandee() <= 0) {
                continue;
            }

            Optional<ArticleConditionnement> conditionnement = articleConditionnementRepository
                    .findFirstByArticleIdOrderByIdAsc(commande.getArticle().getId());
            if (conditionnement.isEmpty()
                    || conditionnement.get().getQuantitePieceStandard() == null
                    || conditionnement.get().getQuantitePieceStandard() <= 0) {
                // Sans conditionnement, on ne sait pas convertir : on ne cree pas de bon.
                continue;
            }
            int piecesParConditionnement = conditionnement.get().getQuantitePieceStandard();

            int piecesPrelevees = 0;
            for (Prelevement prelevement : prelevementRepository.findAllByCommandeId(commande.getId())) {
                piecesPrelevees += prelevement.getQuantitePiecesPrelevees();
            }

            int conditionnementsServis = piecesPrelevees / piecesParConditionnement;
            int reste = commande.getQuantiteDemandee() - conditionnementsServis;
            if (reste > 0) {
                restes.put(commande, reste);
            }
        }

        return restes;
    }

    /**
     * Le bon de reste d'une sortie, s'il existe. Sert a l'afficher (et a imprimer
     * son PDF) juste apres la validation, ou plus tard sur la sortie cloturee.
     */
    @Transactional(readOnly = true)
    public Optional<BonResteResponse> trouverBonReste(Long journalOrigineId) {
        return journalMouvementRepository
                .findFirstByJournalOrigineIdOrderByIdDesc(journalOrigineId)
                .map(bon -> new BonResteResponse(
                        bon.getId(),
                        bon.getReference(),
                        bon.getCommandes() == null ? 0 : bon.getCommandes().size()));
    }

    /**
     * Cree la nouvelle sortie qui reprend le manque du journal d'origine.
     * Renvoie vide si tout a ete servi.
     *
     * Le journal est cree directement (et non par JournalMouvementService.create) :
     * ce bon est une consequence de la sortie validee, il ne doit pas etre bloque
     * par un inventaire en cours.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public Optional<JournalMouvement> creerBonReste(JournalMouvement origine) {
        Map<Commande, Integer> restes = calculerRestes(origine);
        if (restes.isEmpty()) {
            return Optional.empty();
        }

        // SOR-001 -> SOR-001-R1 ; un second reste donne SOR-001-R2.
        long dejaCrees = journalMouvementRepository
                .countByReferenceStartingWith(origine.getReference() + "-R");
        String reference = origine.getReference() + "-R" + (dejaCrees + 1);

        StatutJournalMouvement statut = journalStatutService.trouverStatut(StatutJournalMouvementCode.EN_COURS);

        JournalMouvement bon = new JournalMouvement(
                origine.getFournisseur(),
                reference,
                null, // la piece jointe du client reste sur le journal d'origine
                origine.getNomClient(),
                origine.getTypeMouvementJournal(),
                statut);
        bon.setJournalOrigine(origine);

        JournalMouvement bonSauvegarde = journalMouvementRepository.save(bon);
        journalStatutService.enregistrerStatutInitial(bonSauvegarde);

        List<Commande> nouvellesCommandes = new ArrayList<>();
        for (Map.Entry<Commande, Integer> manque : restes.entrySet()) {
            Commande commande = new Commande();
            commande.setArticle(manque.getKey().getArticle());
            commande.setJournalMouvement(bonSauvegarde);
            commande.setQuantiteDemandee(manque.getValue());
            nouvellesCommandes.add(commande);
        }
        commandeRepository.saveAll(nouvellesCommandes);

        return Optional.of(bonSauvegarde);
    }
}
