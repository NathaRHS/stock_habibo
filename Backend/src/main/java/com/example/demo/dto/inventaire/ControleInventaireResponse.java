package com.example.demo.dto.inventaire;

import java.util.List;

public record ControleInventaireResponse(Long journalId, String reference, String statut, Integer nombreParticipants,List<LigneControleInventaireResponse> details) {

}
