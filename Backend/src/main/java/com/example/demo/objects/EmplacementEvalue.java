package com.example.demo.objects;


import java.util.ArrayList;
import java.util.List;

public class EmplacementEvalue {

    // Informations physiques de l'emplacement
    private Long emplacementId;
    private String nomEmplacement;

    private Long rackId;
    private String nomRack;
    private Integer ordreRack;
    private Integer numeroEtage;
    private Integer ordreDansEtage;

    // Informations de stock et de capacité
    private Long articlePresentId;
    private Long quantitePiecesPresentes;
    private Long conditionnementsPresents;

    private Integer capaciteMaxConditionnements;
    private Long capaciteLibre;

    // Ce que l'algorithme propose de placer ici
    private Long quantiteConditionnementsProposee;

    // Sous-scores, chacun entre 0 et 100
    private double scoreProximite;
    private double scoreCapacite;
    private double scoreFiabilite;
    private double scoreRegroupement;

    // Score final pondéré
    private double scoreFinal;

    // Explications affichables à l'administrateur
    private List<String> raisons = new ArrayList<>();

    public Long getEmplacementId() {
        return emplacementId;
    }

    public void setEmplacementId(Long emplacementId) {
        this.emplacementId = emplacementId;
    }

    public String getNomEmplacement() {
        return nomEmplacement;
    }

    public void setNomEmplacement(String nomEmplacement) {
        this.nomEmplacement = nomEmplacement;
    }

    public Long getRackId() {
        return rackId;
    }

    public void setRackId(Long rackId) {
        this.rackId = rackId;
    }

    public String getNomRack() {
        return nomRack;
    }

    public void setNomRack(String nomRack) {
        this.nomRack = nomRack;
    }

    public Integer getOrdreRack() {
        return ordreRack;
    }

    public void setOrdreRack(Integer ordreRack) {
        this.ordreRack = ordreRack;
    }

    public Integer getNumeroEtage() {
        return numeroEtage;
    }

    public void setNumeroEtage(Integer numeroEtage) {
        this.numeroEtage = numeroEtage;
    }

    public Integer getOrdreDansEtage() {
        return ordreDansEtage;
    }

    public void setOrdreDansEtage(Integer ordreDansEtage) {
        this.ordreDansEtage = ordreDansEtage;
    }

    public Long getArticlePresentId() {
        return articlePresentId;
    }

    public void setArticlePresentId(Long articlePresentId) {
        this.articlePresentId = articlePresentId;
    }

    public Long getQuantitePiecesPresentes() {
        return quantitePiecesPresentes;
    }

    public void setQuantitePiecesPresentes(Long quantitePiecesPresentes) {
        this.quantitePiecesPresentes = quantitePiecesPresentes;
    }

    public Long getConditionnementsPresents() {
        return conditionnementsPresents;
    }

    public void setConditionnementsPresents(Long conditionnementsPresents) {
        this.conditionnementsPresents = conditionnementsPresents;
    }

    public Integer getCapaciteMaxConditionnements() {
        return capaciteMaxConditionnements;
    }

    public void setCapaciteMaxConditionnements(
            Integer capaciteMaxConditionnements) {
        this.capaciteMaxConditionnements = capaciteMaxConditionnements;
    }

    public Long getCapaciteLibre() {
        return capaciteLibre;
    }

    public void setCapaciteLibre(Long capaciteLibre) {
        this.capaciteLibre = capaciteLibre;
    }

    public Long getQuantiteConditionnementsProposee() {
        return quantiteConditionnementsProposee;
    }

    public void setQuantiteConditionnementsProposee(
            Long quantiteConditionnementsProposee) {
        this.quantiteConditionnementsProposee =
                quantiteConditionnementsProposee;
    }

    public double getScoreProximite() {
        return scoreProximite;
    }

    public void setScoreProximite(double scoreProximite) {
        this.scoreProximite = scoreProximite;
    }

    public double getScoreCapacite() {
        return scoreCapacite;
    }

    public void setScoreCapacite(double scoreCapacite) {
        this.scoreCapacite = scoreCapacite;
    }

    public double getScoreFiabilite() {
        return scoreFiabilite;
    }

    public void setScoreFiabilite(double scoreFiabilite) {
        this.scoreFiabilite = scoreFiabilite;
    }

    public double getScoreRegroupement() {
        return scoreRegroupement;
    }

    public void setScoreRegroupement(double scoreRegroupement) {
        this.scoreRegroupement = scoreRegroupement;
    }

    public double getScoreFinal() {
        return scoreFinal;
    }

    public void setScoreFinal(double scoreFinal) {
        this.scoreFinal = scoreFinal;
    }

    public List<String> getRaisons() {
        return raisons;
    }

    public void setRaisons(List<String> raisons) {
        this.raisons = raisons;
    }
}