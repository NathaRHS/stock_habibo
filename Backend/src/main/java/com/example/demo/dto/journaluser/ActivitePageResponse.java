package com.example.demo.dto.journaluser;

import java.util.List;

/** Une page de resultats du journal d'activite. */
public record ActivitePageResponse(
        List<ActiviteResponse> elements,
        long total,
        int page,
        int taille) {
}
