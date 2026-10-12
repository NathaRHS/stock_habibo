package com.example.demo.service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.Commande;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

/**
 * Bon de commande en PDF d'un journal de sortie : une ligne par produit, avec la
 * quantite commandee. Pour un bon de reste (SOR-001-R1), c'est le document qui
 * reprend ce qui n'a pas pu etre servi sur la sortie d'origine.
 *
 * Le document est calcule a la demande a partir des commandes du journal : il
 * n'est pas stocke, donc il reflete toujours les donnees du moment.
 */
@Service
public class BonCommandePdfService {

    private static final DateTimeFormatter FORMAT_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final JournalMouvementRepository journalRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;

    public BonCommandePdfService(
            JournalMouvementRepository journalRepository,
            ArticleConditionnementRepository articleConditionnementRepository) {
        this.journalRepository = journalRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
    }

    @Transactional(readOnly = true)
    public byte[] genererPdf(Long journalId) {
        JournalMouvement journal = journalRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Journal introuvable"));

        if (!"SORTIE".equals(journal.getTypeMouvementJournal().getNomTypeMouvement())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Le bon de commande concerne uniquement une sortie");
        }

        String html = construireHtml(journal);

        try (ByteArrayOutputStream flux = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(html, null);
            builder.toStream(flux);
            builder.run();
            return flux.toByteArray();
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Impossible de générer le bon de commande PDF",
                    exception);
        }
    }

    private String construireHtml(JournalMouvement journal) {
        JournalMouvement origine = journal.getJournalOrigine();
        boolean bonDeReste = origine != null;

        StringBuilder html = new StringBuilder();
        html.append("""
                <!DOCTYPE html><html lang='fr'><head><meta charset='UTF-8' /><style>
                @page { size:A4; margin:18mm 14mm 19mm 14mm; @bottom-center { content:"Page " counter(page) " / " counter(pages); color:#71808a; font-size:8pt; } }
                *{box-sizing:border-box} body{font-family:Helvetica,Arial,sans-serif;color:#18212a;font-size:10pt}
                .header{border-bottom:2px solid #01498e;padding-bottom:14px;margin-bottom:18px}
                .brand{color:#01498e;font-size:11pt;font-weight:bold;letter-spacing:1px}
                h1{margin:8px 0 4px;font-size:22pt;font-weight:500}
                .subtitle{color:#667482;margin:0}
                .meta{width:100%;border-collapse:collapse;margin-bottom:18px}
                .meta td{width:25%;padding:10px;border:1px solid #dfe4e8;vertical-align:top}
                .label{display:block;color:#71808a;font-size:8pt;font-weight:bold;text-transform:uppercase}
                .meta strong{display:block;margin-top:5px;font-size:10pt}
                table.lignes{width:100%;border-collapse:collapse}
                .lignes th{padding:8px;background:#01498e;color:#fff;font-size:8pt;text-align:left;text-transform:uppercase}
                .lignes td{padding:9px 8px;border-bottom:1px solid #dfe4e8;vertical-align:top}
                .lignes tr:nth-child(even){background:#f7f9fa}
                .muted{color:#71808a;font-size:8pt}.right{text-align:right}
                .quantite{font-size:12pt;font-weight:bold}
                </style></head><body>""");

        html.append("<div class='header'><div class='brand'>HABIBO WMS - GESTION D'ENTREPOT</div>")
                .append("<h1>Bon de commande</h1><p class='subtitle'>")
                .append(bonDeReste
                        ? "Produits restant a servir, repris de la sortie " + texteHtml(origine.getReference()) + "."
                        : "Produits commandes pour cette sortie.")
                .append("</p></div>");

        html.append("<table class='meta'><tr>")
                .append(cellule("Reference", journal.getReference()))
                .append(cellule("Client", journal.getNomClient()))
                .append(cellule("Date d'edition", FORMAT_DATE.format(LocalDateTime.now())))
                .append(cellule("Sortie d'origine", bonDeReste ? origine.getReference() : "-"))
                .append("</tr></table>");

        html.append("<table class='lignes'><thead><tr>")
                .append("<th>Produit</th><th>Code-barres</th><th>Conditionnement</th><th class='right'>Quantite</th>")
                .append("</tr></thead><tbody>");

        if (journal.getCommandes() == null || journal.getCommandes().isEmpty()) {
            html.append("<tr><td colspan='4'>Aucun produit dans cette commande.</td></tr>");
        } else {
            for (Commande commande : journal.getCommandes()) {
                Article article = commande.getArticle();

                // Libelle du conditionnement (pack, carton...) du premier conditionnement.
                String conditionnement = articleConditionnementRepository
                        .findFirstByArticleIdOrderByIdAsc(article.getId())
                        .map(ArticleConditionnement::getTypeConditionnement)
                        .map(type -> type.getNomConditionnement())
                        .orElse("-");

                html.append("<tr><td><strong>").append(texteHtml(article.getNomArticle())).append("</strong>");
                if (article.getContenanceValeur() != null && article.getUnite() != null) {
                    html.append("<br /><span class='muted'>")
                            .append(article.getContenanceValeur().stripTrailingZeros().toPlainString())
                            .append(" ").append(texteHtml(article.getUnite().getNomUnite()))
                            .append("</span>");
                }
                html.append("</td><td>").append(texteHtml(article.getCodeBar()))
                        .append("</td><td>").append(texteHtml(conditionnement))
                        .append("</td><td class='right quantite'>")
                        .append(commande.getQuantiteDemandee())
                        .append("</td></tr>");
            }
        }

        html.append("</tbody></table></body></html>");
        return html.toString();
    }

    private String cellule(String libelle, String valeur) {
        return "<td><span class='label'>" + texteHtml(libelle) + "</span><strong>" + texteHtml(valeur)
                + "</strong></td>";
    }

    // Les valeurs viennent de la base : on echappe tout ce qui va dans le HTML.
    private String texteHtml(String valeur) {
        if (valeur == null) {
            return "-";
        }
        return valeur.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}
