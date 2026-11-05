package com.example.demo.service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.article.CreateArticleCompletRequest;
import com.example.demo.dto.importation.ImportResponse;
import com.example.demo.dto.importation.LigneErreur;
import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.Societe;
import com.example.demo.entity.TypeConditionnement;
import com.example.demo.entity.TypeEvenementUser;
import com.example.demo.entity.TypeProduit;
import com.example.demo.entity.Unite;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.ArticleRepository;
import com.example.demo.repository.SocieteRepository;
import com.example.demo.repository.TypeConditionnementRepository;
import com.example.demo.repository.TypeProduitRepository;
import com.example.demo.repository.UniteRepository;

/**
 * Import d'articles complets depuis un CSV : une ligne = un article, son
 * conditionnement et sa capacite palette. Tout ou rien : si une ligne est
 * refusee, aucun article n'est cree.
 */
@Service
public class ArticleImportService {

    private static final int LIGNES_MAX = 5000;

    private static final String NOM = "nom_article";
    private static final String CODE_ARTICLE = "code_barres_article";
    private static final String TYPE_PRODUIT = "type_produit";
    private static final String UNITE = "unite";
    private static final String CONTENANCE = "contenance";
    private static final String TYPE_CONDITIONNEMENT = "type_conditionnement";
    private static final String CODE_CONDITIONNEMENT = "code_barres_conditionnement";
    private static final String PIECES = "pieces_par_conditionnement";
    private static final String PALETTE = "quantite_max_palette";
    private static final String SOCIETE = "societe";

    private static final List<String> COLONNES = List.of(
            NOM, CODE_ARTICLE, TYPE_PRODUIT, UNITE, CONTENANCE,
            TYPE_CONDITIONNEMENT, CODE_CONDITIONNEMENT, PIECES, PALETTE, SOCIETE);

    private final CsvService csvService;
    private final ArticleCompletService articleCompletService;
    private final ArticleRepository articleRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;
    private final TypeProduitRepository typeProduitRepository;
    private final TypeConditionnementRepository typeConditionnementRepository;
    private final UniteRepository uniteRepository;
    private final SocieteRepository societeRepository;
    private final JournalUserService journalUserService;

    public ArticleImportService(
            CsvService csvService,
            ArticleCompletService articleCompletService,
            ArticleRepository articleRepository,
            ArticleConditionnementRepository articleConditionnementRepository,
            TypeProduitRepository typeProduitRepository,
            TypeConditionnementRepository typeConditionnementRepository,
            UniteRepository uniteRepository,
            SocieteRepository societeRepository,
            JournalUserService journalUserService) {
        this.societeRepository = societeRepository;
        this.csvService = csvService;
        this.articleCompletService = articleCompletService;
        this.articleRepository = articleRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
        this.typeProduitRepository = typeProduitRepository;
        this.typeConditionnementRepository = typeConditionnementRepository;
        this.uniteRepository = uniteRepository;
        this.journalUserService = journalUserService;
    }

    /** Fichier modele : les colonnes attendues et deux lignes d'exemple. */
    public byte[] modele() {
        return csvService.ecrire(COLONNES, List.of(
                List.of("Coca-Cola 30 cl", "2000000000015", "BOISSON", "cL", "30",
                        "PACK", "3000000000016", "24", "120", "HB"),
                List.of("Savon de Marseille", "2000000000077", "HYGIENE", "", "",
                        "CARTON", "3000000000078", "48", "200", "HH")));
    }

    @Transactional
    public ImportResponse importer(MultipartFile fichier) {
        List<List<String>> lignes = csvService.lire(fichier);
        Map<String, Integer> positions = positionsColonnes(lignes.get(0));

        if (lignes.size() - 1 > LIGNES_MAX) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le fichier depasse " + LIGNES_MAX + " lignes");
        }

        List<LigneErreur> erreurs = new ArrayList<>();
        List<Integer> numeros = new ArrayList<>();
        List<CreateArticleCompletRequest> requetes = new ArrayList<>();
        Set<String> codesArticles = new HashSet<>();
        Set<String> codesConditionnements = new HashSet<>();

        // 1. On controle tout le fichier avant d'ecrire quoi que ce soit.
        for (int i = 1; i < lignes.size(); i++) {
            List<String> ligne = lignes.get(i);
            if (estVide(ligne)) {
                continue;
            }

            int numero = i + 1; // numero de ligne dans le fichier (l'en-tete est la ligne 1)
            List<String> problemes = new ArrayList<>();
            CreateArticleCompletRequest requete = lireLigne(
                    ligne, positions, problemes, codesArticles, codesConditionnements);

            if (problemes.isEmpty()) {
                requetes.add(requete);
                numeros.add(numero);
            } else {
                for (String probleme : problemes) {
                    erreurs.add(new LigneErreur(numero, probleme));
                }
            }
        }

        if (erreurs.isEmpty() && requetes.isEmpty()) {
            erreurs.add(new LigneErreur(1, "Le fichier ne contient aucun article"));
        }
        if (!erreurs.isEmpty()) {
            return new ImportResponse(0, erreurs);
        }

        // 2. Creation : la moindre erreur annule tout (transaction).
        for (int i = 0; i < requetes.size(); i++) {
            try {
                articleCompletService.construireArticleComplet(requetes.get(i));
            } catch (ResponseStatusException exception) {
                throw new ResponseStatusException(
                        exception.getStatusCode(),
                        "Ligne " + numeros.get(i) + " : " + exception.getReason());
            }
        }

        journalUserService.enregistrer(
                TypeEvenementUser.ARTICLE_CREE,
                CibleEvenement.ARTICLE,
                null,
                "import CSV : " + requetes.size() + " article(s)");

        return new ImportResponse(requetes.size(), List.of());
    }

    // ------------------------------------------------------------------

    private Map<String, Integer> positionsColonnes(List<String> entete) {
        Map<String, Integer> positions = new HashMap<>();
        for (int i = 0; i < entete.size(); i++) {
            positions.put(entete.get(i).trim().toLowerCase(), i);
        }

        List<String> manquantes = COLONNES.stream()
                .filter(colonne -> !positions.containsKey(colonne))
                .toList();
        if (!manquantes.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Colonnes manquantes : " + String.join(", ", manquantes));
        }
        return positions;
    }

    /** Lit une ligne. Les problemes trouves sont ajoutes a la liste ; la requete n'est valable que sans probleme. */
    private CreateArticleCompletRequest lireLigne(
            List<String> ligne,
            Map<String, Integer> positions,
            List<String> problemes,
            Set<String> codesArticles,
            Set<String> codesConditionnements) {

        String nom = valeur(ligne, positions, NOM);
        String codeArticle = valeur(ligne, positions, CODE_ARTICLE);
        String codeConditionnement = valeur(ligne, positions, CODE_CONDITIONNEMENT);

        if (nom.isEmpty()) {
            problemes.add("Le nom de l'article est obligatoire");
        }

        if (codeArticle.isEmpty()) {
            problemes.add("Le code-barres de l'article est obligatoire");
        } else if (!codesArticles.add(codeArticle)) {
            problemes.add("Code-barres d'article en double dans le fichier : " + codeArticle);
        } else if (articleRepository.findByCodeBar(codeArticle).isPresent()) {
            problemes.add("Code-barres d'article deja utilise : " + codeArticle);
        }

        if (codeConditionnement.isEmpty()) {
            problemes.add("Le code-barres du conditionnement est obligatoire");
        } else if (!codesConditionnements.add(codeConditionnement)) {
            problemes.add("Code-barres de conditionnement en double dans le fichier : " + codeConditionnement);
        } else if (articleConditionnementRepository.findByCodeBarres(codeConditionnement).isPresent()) {
            problemes.add("Code-barres de conditionnement deja utilise : " + codeConditionnement);
        }

        Long typeProduitId = null;
        String nomTypeProduit = valeur(ligne, positions, TYPE_PRODUIT);
        if (nomTypeProduit.isEmpty()) {
            problemes.add("Le type de produit est obligatoire");
        } else {
            typeProduitId = typeProduitRepository.findByNomType(nomTypeProduit)
                    .map(TypeProduit::getId)
                    .orElse(null);
            if (typeProduitId == null) {
                problemes.add("Type de produit inconnu : " + nomTypeProduit);
            }
        }

        Long typeConditionnementId = null;
        String nomTypeConditionnement = valeur(ligne, positions, TYPE_CONDITIONNEMENT);
        if (nomTypeConditionnement.isEmpty()) {
            problemes.add("Le type de conditionnement est obligatoire");
        } else {
            typeConditionnementId = typeConditionnementRepository
                    .findByNomConditionnement(nomTypeConditionnement)
                    .map(TypeConditionnement::getId)
                    .orElse(null);
            if (typeConditionnementId == null) {
                problemes.add("Type de conditionnement inconnu : " + nomTypeConditionnement);
            }
        }

        // La contenance et l'unite vont ensemble : toutes les deux ou aucune.
        BigDecimal contenance = null;
        Long uniteId = null;
        String texteContenance = valeur(ligne, positions, CONTENANCE);
        String nomUnite = valeur(ligne, positions, UNITE);
        if (!texteContenance.isEmpty() || !nomUnite.isEmpty()) {
            if (texteContenance.isEmpty() || nomUnite.isEmpty()) {
                problemes.add("La contenance et l'unite vont ensemble");
            } else {
                contenance = lireDecimalPositif(texteContenance, "La contenance", problemes);
                uniteId = uniteRepository.findByNomUnite(nomUnite)
                        .map(Unite::getId)
                        .orElse(null);
                if (uniteId == null) {
                    problemes.add("Unite inconnue : " + nomUnite);
                }
            }
        }

        // La societe est obligatoire : elle decide des entrees qui pourront scanner l'article.
        Long societeId = null;
        String nomSociete = valeur(ligne, positions, SOCIETE);
        if (nomSociete.isEmpty()) {
            problemes.add("La societe est obligatoire");
        } else {
            societeId = societeRepository.findByNomSocieteIgnoreCase(nomSociete)
                    .map(Societe::getId)
                    .orElse(null);
            if (societeId == null) {
                problemes.add("Societe inconnue : " + nomSociete);
            }
        }

        Integer pieces = lireEntierPositif(
                valeur(ligne, positions, PIECES), "Les pieces par conditionnement", problemes);
        Integer quantitePalette = lireEntierPositif(
                valeur(ligne, positions, PALETTE), "La quantite maximale de palette", problemes);

        return new CreateArticleCompletRequest(
                new CreateArticleCompletRequest.ArticleInfo(
                        nom, codeArticle, typeProduitId, typeConditionnementId, contenance, uniteId,
                        societeId),
                new CreateArticleCompletRequest.ConditionnementInfo(
                        typeConditionnementId, codeConditionnement, pieces),
                new CreateArticleCompletRequest.PaletteInfo(quantitePalette));
    }

    private String valeur(List<String> ligne, Map<String, Integer> positions, String colonne) {
        int position = positions.get(colonne);
        return position < ligne.size() ? ligne.get(position).trim() : "";
    }

    private boolean estVide(List<String> ligne) {
        return ligne.stream().allMatch(champ -> champ.trim().isEmpty());
    }

    private Integer lireEntierPositif(String texte, String libelle, List<String> problemes) {
        try {
            int valeur = Integer.parseInt(texte);
            if (valeur > 0) {
                return valeur;
            }
        } catch (NumberFormatException exception) {
            // Message ci-dessous.
        }
        problemes.add(libelle + " doit etre un entier superieur a 0 (recu : \"" + texte + "\")");
        return null;
    }

    private BigDecimal lireDecimalPositif(String texte, String libelle, List<String> problemes) {
        try {
            BigDecimal valeur = new BigDecimal(texte.replace(',', '.'));
            if (valeur.signum() > 0) {
                return valeur;
            }
        } catch (NumberFormatException exception) {
            // Message ci-dessous.
        }
        problemes.add(libelle + " doit etre un nombre superieur a 0 (recu : \"" + texte + "\")");
        return null;
    }
}
