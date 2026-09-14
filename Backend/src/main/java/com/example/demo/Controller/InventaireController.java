package com.example.demo.Controller;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.ControleInventaireResponse;
import com.example.demo.service.InventaireService;
import com.example.demo.service.RapportInventaireService;

@RestController
@RequestMapping("/inventaire")
public class InventaireController {
    private final InventaireService inventaireService;
    private final RapportInventaireService rapportInventaireService;

    public InventaireController(InventaireService inventaireService, RapportInventaireService rapportInventaireService) {
        this.inventaireService = inventaireService;
        this.rapportInventaireService = rapportInventaireService;
    }

    @GetMapping("/{id}")
    public ControleInventaireResponse inventaire(@PathVariable Long id) {
        System.out.println("id: " + id);
        return inventaireService.constructInventaire(id);
    }


    @GetMapping(value = "/{id}/rapport.pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> genererRapportInventaire(@PathVariable Long id) {
        byte[] pdf = rapportInventaireService.genererPdf(id);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=rapport-inventaire-" + id + ".pdf")
                .contentLength(pdf.length)
                .body(pdf);
    }
}
