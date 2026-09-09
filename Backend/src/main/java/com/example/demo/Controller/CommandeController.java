package com.example.demo.Controller;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.service.*;
import com.example.demo.dto.*;

@RestController
@RequestMapping("/commande")
public class CommandeController {

    public final CommandeService commandeService;

    public CommandeController(CommandeService commandeService) {
        this.commandeService = commandeService;
    }

    @GetMapping("/{id}")
    public CommandeResponseAll getAll(@PathVariable Long id) {
        return commandeService.getAll(id);
    }

    @PostMapping("/insertAllCommande/{idJournal}")
    public CommandeResponseAll insertAllCommande(@RequestBody List<CommandeCreateRequest> commandes,
            @PathVariable Long idJournal) {
        return commandeService.InsertAllCommande(commandes, idJournal);
    }

    @GetMapping("/proposerEmplacement/{id}")
    public List<MeilleurEmplacementResponse> proposerEmplacement(@PathVariable Long idCommande) {
        return commandeService.proposerEmplacement(idCommande);

    }

    @PostMapping ("/savePrelevement")
    public PrelevementResponse savePrelevement(@RequestBody AjoutCommandeRequest ajoutCommandeRequest) {
        return commandeService.UpdateCommandeAndDetailJournal(ajoutCommandeRequest);

    }

}
