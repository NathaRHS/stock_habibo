package com.example.demo.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.*;
import com.example.demo.repository.*;

import com.example.demo.entity.*;

@Service
public class CommandeService {

    private final JournalMouvementRepository journalMouvementRepository;
    private final ArticleRepository articleRepository;
    private final CommandeRepository commandeRepository;

    public CommandeService(JournalMouvementRepository journalMouvementRepository, ArticleRepository articleRepository,
            CommandeRepository commandeRepository) {
        this.journalMouvementRepository = journalMouvementRepository;
        this.articleRepository = articleRepository;
        this.commandeRepository = commandeRepository;

    }

    @Transactional 
    public CommandeResponseAll InsertAllCommande(List<CommandeCreateRequest> commandes, Long idJournal) {
        List<Commande> commandeAInserer = new ArrayList<>();
        for (CommandeCreateRequest commande : commandes) {
            JournalMouvement journal = journalMouvementRepository.findById(idJournal).orElseThrow(
                    () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Journal de la commande introuvable"));
            if (!journal.getTypeMouvementJournal().getNomTypeMouvement().equals("SORTIE")) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Cette session n'est pas une session de sortie");
            }

            if(commande == null){
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La commande est null");
            }
            Article article = articleRepository.findById(commande.idProduit())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "article introuvable"));

            Commande newCommande = new Commande();
            newCommande.setArticle(article);
            newCommande.setJournalMouvement(journal);
            newCommande.setQuantiteDemandee(commande.quantiteDemande());
            commandeAInserer.add(newCommande);
        }
        List<Commande> commandeValiny = commandeRepository.saveAll(commandeAInserer);
        List<CommandeResponse> responses = new ArrayList<>();

        for (Commande commandeSauvegardee : commandeValiny) {
            CommandeResponse response = new CommandeResponse(
                    commandeSauvegardee.getId(),
                    commandeSauvegardee.getJournalMouvement().getId(),
                    commandeSauvegardee.getArticle().getId(),
                    commandeSauvegardee.getArticle().getNomArticle(),
                    commandeSauvegardee.getQuantiteDemandee());

            responses.add(response);
        }

        return new CommandeResponseAll(responses);

    }

    // public CommandeResponse versResponse(Commande commande){
    // CommandeResponse commandeResponse = new
    // CommandeResponse(commande.getJournalMouvement().getId(),commande.getArticle().getNomArticle(),commande.getArticle().getId(),commande.getRemarque(),commande.getQuantiteDemandee(),commande.getQuantiteReel(),commande.getUser().getMatricule(),commande.getEtat());
    // }

}
