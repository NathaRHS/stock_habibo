package com.example.demo.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "t_article_conditionnement")
public class ArticleConditionnement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "article_id", nullable = false)
    private Article article;

    @ManyToOne(optional = false)
    @JoinColumn(name = "type_conditionnement_id", nullable = false)
    private TypeConditionnement typeConditionnement;

    @Column(name = "code_barres")
    private String codeBarres;

    @Column(name = "quantite_piece_standard", nullable = false)
    private Integer quantitePieceStandard;

    @OneToOne(mappedBy = "articleConditionnement", fetch = FetchType.LAZY)
    private PaletteConditionnement paletteConditionnement;

    public ArticleConditionnement() {
    }

    public ArticleConditionnement(
            Article article,
            TypeConditionnement typeConditionnement,
            String codeBarres,
            Integer quantitePieceStandard) {
        this.article = article;
        this.typeConditionnement = typeConditionnement;
        this.codeBarres = codeBarres;
        this.quantitePieceStandard = quantitePieceStandard;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Article getArticle() {
        return article;
    }

    public void setArticle(Article article) {
        this.article = article;
    }

    public TypeConditionnement getTypeConditionnement() {
        return typeConditionnement;
    }

    public void setTypeConditionnement(TypeConditionnement typeConditionnement) {
        this.typeConditionnement = typeConditionnement;
    }

    public String getCodeBarres() {
        return codeBarres;
    }

    public void setCodeBarres(String codeBarres) {
        this.codeBarres = codeBarres;
    }

    public Integer getQuantitePieceStandard() {
        return quantitePieceStandard;
    }

    public void setQuantitePieceStandard(Integer quantitePieceStandard) {
        this.quantitePieceStandard = quantitePieceStandard;
    }

    public PaletteConditionnement getPaletteConditionnement() {
        return paletteConditionnement;
    }

    public void setPaletteConditionnement(PaletteConditionnement paletteConditionnement) {
        this.paletteConditionnement = paletteConditionnement;
    }
}
