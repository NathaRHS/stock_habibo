package com.example.demo.service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.ControleInventaireResponse;
import com.example.demo.dto.LigneControleInventaireResponse;
import com.example.demo.dto.ParticipantJournalResponse;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;

@Service
public class RapportInventaireService {

    private static final DateTimeFormatter FORMAT_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final InventaireService inventaireService;
    private final UserJournalMouvementService userJournalMouvementService;

    public RapportInventaireService(
            InventaireService inventaireService,
            UserJournalMouvementService userJournalMouvementService) {
        this.inventaireService = inventaireService;
        this.userJournalMouvementService = userJournalMouvementService;
    }

    public byte[] genererPdf(Long journalId) {
        ControleInventaireResponse inventaire = inventaireService.constructInventaire(journalId);
        List<ParticipantJournalResponse> participants = userJournalMouvementService
                .trouverParticipants(journalId);
        List<LigneControleInventaireResponse> lignes = inventaire.details();
        SyntheseInventaire synthese = calculerSynthese(lignes);
        String html = construireHtml(inventaire, participants, lignes, synthese);

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(html, null);
            builder.toStream(outputStream);
            builder.run();
            return outputStream.toByteArray();
        } catch (Exception exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Impossible de générer le rapport PDF d'inventaire",
                    exception);
        }
    }

    private SyntheseInventaire calculerSynthese(List<LigneControleInventaireResponse> lignes) {
        int conformes = 0;
        int manques = 0;
        int surplus = 0;
        long ecartAbsoluTotal = 0;
        Set<Long> emplacements = new HashSet<>();

        for (LigneControleInventaireResponse ligne : lignes) {
            long ecart = ligne.ecart() == null ? 0 : ligne.ecart();
            emplacements.add(ligne.EmplacementId());

            if (ecart == 0) {
                conformes++;
            } else if (ecart < 0) {
                manques++;
            } else {
                surplus++;
            }
            ecartAbsoluTotal += Math.abs(ecart);
        }

        return new SyntheseInventaire(emplacements.size(), conformes, manques, surplus, ecartAbsoluTotal);
    }

    private String construireHtml(
            ControleInventaireResponse inventaire,
            List<ParticipantJournalResponse> participants,
            List<LigneControleInventaireResponse> lignes,
            SyntheseInventaire synthese) {

        StringBuilder html = new StringBuilder();
        html.append("""
                <!DOCTYPE html><html lang='fr'><head><meta charset='UTF-8' /><style>
                @page { size:A4; margin:18mm 14mm 19mm 14mm; @bottom-center { content:"Page " counter(page) " / " counter(pages); color:#71808a; font-size:8pt; } }
                *{box-sizing:border-box} body{font-family:Helvetica,Arial,sans-serif;color:#18212a;font-size:10pt}
                .header{border-bottom:2px solid #01498e;padding-bottom:14px;margin-bottom:18px}.brand{color:#01498e;font-size:11pt;font-weight:bold;letter-spacing:1px}h1{margin:8px 0 4px;font-size:22pt;font-weight:500}.subtitle{color:#667482;margin:0}.reference{float:right;margin-top:-47px;padding:9px 12px;border-left:3px solid #01498e;background:#f4f8fb}.reference small,.label{display:block;color:#71808a;font-size:8pt;font-weight:bold;text-transform:uppercase}.reference strong{display:block;margin-top:4px;font-size:11pt}
                .meta,.summary{width:100%;border-collapse:collapse;margin-bottom:15px}.meta td{width:25%;padding:10px;border:1px solid #dfe4e8;vertical-align:top}.meta strong{display:block;margin-top:5px;font-size:10pt}.summary td{width:20%;padding:11px;border:1px solid #dfe4e8;vertical-align:top}.summary .number{display:block;margin-top:8px;font-size:20pt;font-weight:normal}.success{color:#1f9d62}.danger{color:#d64545}.warning{color:#c57712}
                h2{margin:20px 0 8px;font-size:13pt}.report-table{width:100%;border-collapse:collapse}.report-table th{padding:8px;background:#01498e;color:#fff;font-size:8pt;text-align:left;text-transform:uppercase}.report-table td{padding:8px;border-bottom:1px solid #dfe4e8;vertical-align:top}.report-table tr:nth-child(even){background:#f7f9fa}.muted{color:#71808a;font-size:8pt}.right{text-align:right}.badge{padding:3px 6px;border-radius:8px;font-size:8pt;font-weight:bold}.badge-success{color:#15714b;background:#e8f7ef}.badge-danger{color:#b63232;background:#fbecec}.badge-warning{color:#9b5d08;background:#fff5df}.participants{margin-top:16px;padding:12px;border:1px solid #dfe4e8;background:#fbfcfd}.participant{display:inline-block;width:49%;margin:5px 0}.notice{margin-top:18px;padding:11px 13px;border-left:3px solid #d99016;background:#fff9ec;color:#6e5725;font-size:9pt}
                </style></head><body><div class='header'><div class='brand'>HABIBO WMS - GESTION D'ENTREPOT</div><h1>Rapport d'inventaire</h1><p class='subtitle'>Resultat du comptage physique et comparaison avec le stock theorique.</p><div class='reference'><small>Reference</small><strong>""")
                .append(texteHtml(inventaire.reference()))
                .append("</strong><small>Statut : ").append(texteHtml(inventaire.statut()))
                .append("</small></div></div>");

        html.append("<table class='meta'><tr>")
                .append(celluleMeta("Date d'edition", FORMAT_DATE.format(LocalDateTime.now())))
                .append(celluleMeta("Statut de la session", inventaire.statut()))
                .append(celluleMeta("Participants", String.valueOf(participants.size())))
                .append(celluleMeta("Nature", "Inventaire physique"))
                .append("</tr></table>");

        html.append("<table class='summary'><tr>")
                .append(celluleSynthese("Emplacements comptes", synthese.nombreEmplacements(), ""))
                .append(celluleSynthese("Lignes conformes", synthese.conformes(), "success"))
                .append(celluleSynthese("Manques", synthese.manques(), "danger"))
                .append(celluleSynthese("Surplus", synthese.surplus(), "warning"))
                .append(celluleSynthese("Ecart absolu total", synthese.ecartAbsoluTotal(), ""))
                .append("</tr></table>");

        html.append("<h2>Resultats detailles</h2><table class='report-table'><thead><tr>")
                .append("<th>Emplacement</th><th>Article</th><th class='right'>Theorique</th><th class='right'>Compte</th><th class='right'>Ecart</th><th>Resultat</th>")
                .append("</tr></thead><tbody>");

        for (LigneControleInventaireResponse ligne : lignes) {
            long ecart = ligne.ecart() == null ? 0 : ligne.ecart();
            String resultat = ecart == 0 ? "Conforme" : ecart < 0 ? "Manque" : "Surplus";
            String classe = ecart == 0 ? "badge-success" : ecart < 0 ? "badge-danger" : "badge-warning";

            html.append("<tr><td><strong>").append(texteHtml(ligne.nomEmplacement()))
                    .append("</strong><br /><span class='muted'>").append(texteHtml(ligne.nomRack()))
                    .append(" - Niveau ").append(ligne.numeroEtage()).append("</span></td><td>")
                    .append(texteHtml(ligne.nomArticle())).append("</td><td class='right'>")
                    .append(ligne.quantiteTheorique()).append("</td><td class='right'>")
                    .append(ligne.quanantiteComptee()).append("</td><td class='right'>")
                    .append(ecart > 0 ? "+" : "").append(ecart)
                    .append("</td><td><span class='badge ").append(classe).append("'>")
                    .append(resultat).append("</span></td></tr>");
        }

        html.append("</tbody></table><div class='participants'><span class='label'>Participants au comptage</span>");
        if (participants.isEmpty()) {
            html.append("<p>Aucun participant enregistre.</p>");
        } else {
            for (ParticipantJournalResponse participant : participants) {
                html.append("<div class='participant'><strong>").append(texteHtml(participant.username()))
                        .append("</strong><br /><span class='muted'>").append(texteHtml(participant.matricule()))
                        .append(" - ").append(participant.statut()).append("</span></div>");
            }
        }

        html.append("</div><div class='notice'>Ce rapport constate les ecarts entre le stock theorique et le comptage physique. Il ne modifie pas automatiquement le stock. Toute regularisation doit suivre la procedure interne de l'entreprise.</div></body></html>");
        return html.toString();
    }

    private String celluleMeta(String libelle, String valeur) {
        return "<td><span class='label'>" + texteHtml(libelle) + "</span><strong>" + texteHtml(valeur) + "</strong></td>";
    }

    private String celluleSynthese(String libelle, long valeur, String classe) {
        return "<td><span class='label'>" + texteHtml(libelle) + "</span><strong class='number " + classe + "'>" + valeur + "</strong></td>";
    }

    private String texteHtml(String valeur) {
        if (valeur == null) return "-";
        return valeur.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }

    private record SyntheseInventaire(int nombreEmplacements, int conformes, int manques, int surplus, long ecartAbsoluTotal) {
    }
}
