package com.example.demo.projection;

import java.time.LocalDateTime;

/**
 * Une ligne de la liste de base de l'entrepot : un mouvement, ou le solde
 * initial d'un (emplacement, article) avant la periode.
 */
public interface ActiviteEmplacementProjection {
    // Vide pour un solde initial.
    Long getId();

    Long getEmplacementId();

    Long getArticleId();

    String getNomArticle();

    LocalDateTime getDateMouvement();

    // ENTREE, SORTIE... ou SOLDE_INITIAL.
    String getTypeMouvement();

    // Quantite en pieces, signee : entree positive, sortie negative.
    Long getQuantite();

    String getJournalReference();

    String getMatricule();
}
