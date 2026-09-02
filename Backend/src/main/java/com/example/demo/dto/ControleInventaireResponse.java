package com.example.demo.dto;

import java.util.List;

public record ControleInventaireResponse(Long journalId, String reference, String statut, Integer nombreParticipants,List<LigneControleInventaireResponse> details) {

}
