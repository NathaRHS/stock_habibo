import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import Sidebar from "../components/Sidebar";
import {
  chargerDonneesControleInventaire,
  chargerParticipantsInventaire,
  telechargerRapportInventaire,
} from "../services/inventaireService";
import "./css/Recapitulatif.css";

function resultatEcart(ecart) {
  if (ecart === 0) return { libelle: "Conforme", classe: "is-conforme" };
  if (ecart < 0) return { libelle: "Manque", classe: "is-manque" };
  return { libelle: "Surplus", classe: "is-surplus" };
}

function Recapitulatif() {
  const { id } = useParams();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [reponseGeneral, setReponseGeneral] = useState(null);
  const [participants, setParticipants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [generationPdf, setGenerationPdf] = useState(false);

  useEffect(() => {
    async function chargerRapport() {
      try {
        const [donneesControle, donneesParticipants] = await Promise.all([
          chargerDonneesControleInventaire(springUrl, id),
          chargerParticipantsInventaire(springUrl, id),
        ]);
        setReponseGeneral(donneesControle);
        setParticipants(donneesParticipants);
      } catch (erreur) {
        setError(erreur.message || "Impossible de charger le rapport.");
      } finally {
        setLoading(false);
      }
    }
    chargerRapport();
  }, [id, springUrl]);

  const inventaire = reponseGeneral?.inventaire;
  const lignes = inventaire?.details ?? [];
  const nombreEmplacements = new Set(lignes.map((ligne) => ligne.emplacementId)).size;
  const lignesConformes = lignes.filter((ligne) => ligne.ecart === 0);
  const lignesManquantes = lignes.filter((ligne) => ligne.ecart < 0);
  const lignesSurplus = lignes.filter((ligne) => ligne.ecart > 0);
  const ecartTotal = lignes.reduce((total, ligne) => total + Math.abs(ligne.ecart ?? 0), 0);
  const dateEdition = new Intl.DateTimeFormat("fr-FR", { dateStyle: "long", timeStyle: "short" }).format(new Date());

  async function telechargerPdf() {
    try {
      setGenerationPdf(true);
      setError("");
      const pdf = await telechargerRapportInventaire(springUrl, id);
      const url = URL.createObjectURL(pdf);
      const lien = document.createElement("a");
      lien.href = url;
      lien.download = `rapport-inventaire-${inventaire.reference}.pdf`;
      document.body.appendChild(lien);
      lien.click();
      lien.remove();
      URL.revokeObjectURL(url);
    } catch (erreur) {
      setError(erreur.message || "Impossible de télécharger le PDF.");
    } finally {
      setGenerationPdf(false);
    }
  }

  if (loading) return <div className="rapport-message">Chargement du rapport…</div>;
  if (error || !inventaire) return <div className="rapport-message rapport-message-error" role="alert">{error || "Le rapport demandé est introuvable."}</div>;

  return (
    <div className="rapport-page-shell">
      <Sidebar />
      <section className="rapport-workspace">
        <header className="rapport-topbar">
          <p>Inventaires / {inventaire.reference} / Rapport</p>
          <div className="rapport-topbar-actions">
            <Link to={`/inventaire/${id}`}>Retour au contrôle</Link>
            <button type="button" disabled={generationPdf} onClick={telechargerPdf}><span className="material-symbols-outlined">picture_as_pdf</span>{generationPdf ? "Génération…" : "Télécharger le PDF"}</button>
          </div>
        </header>

        <main className="rapport-content">
          {error && <div className="rapport-download-error" role="alert">{error}</div>}
          <header className="rapport-heading">
            <div><span className="rapport-kicker">Document de clôture</span><h1>Rapport d’inventaire</h1><p>Résultat du comptage physique et comparaison avec le stock théorique.</p></div>
            <div className="rapport-reference"><span>Référence</span><strong>{inventaire.reference}</strong><small className={`rapport-status rapport-status-${inventaire.statut === "VALIDE" ? "success" : "progress"}`}><i />{inventaire.statut}</small></div>
          </header>

          <section className="rapport-meta">
            <div><span>Date d’édition</span><strong>{dateEdition}</strong></div>
            <div><span>Participants</span><strong>{participants.length}</strong></div>
            <div><span>Statut de la session</span><strong>{inventaire.statut}</strong></div>
            <div><span>Nature</span><strong>Inventaire physique</strong></div>
          </section>

          <section className="rapport-summary">
            <article><span>Emplacements comptés</span><strong>{nombreEmplacements}</strong><small>sur les lignes enregistrées</small></article>
            <article className="summary-success"><span>Lignes conformes</span><strong>{lignesConformes.length}</strong><small>écart nul</small></article>
            <article className="summary-danger"><span>Manques</span><strong>{lignesManquantes.length}</strong><small>écart négatif</small></article>
            <article className="summary-warning"><span>Surplus</span><strong>{lignesSurplus.length}</strong><small>écart positif</small></article>
            <article><span>Écart absolu total</span><strong>{ecartTotal}</strong><small>pièces à examiner</small></article>
          </section>

          <section className="rapport-main-grid">
            <section className="rapport-panel">
              <header className="rapport-panel-head"><div><h2>Résultats détaillés</h2><p>{lignes.length} ligne{lignes.length > 1 ? "s" : ""} de comptage enregistrée{lignes.length > 1 ? "s" : ""}</p></div><span className="rapport-panel-note">Théorique / compté / écart</span></header>
              {lignes.length === 0 ? <div className="rapport-empty">Aucun comptage n’a été enregistré pour cet inventaire.</div> : <div className="rapport-table-scroll"><table className="rapport-table"><thead><tr><th>Emplacement</th><th>Article</th><th>Théorique</th><th>Compté</th><th>Écart</th><th>Résultat</th></tr></thead><tbody>
                {lignes.map((ligne) => {
                  const resultat = resultatEcart(ligne.ecart);
                  return <tr key={`${ligne.emplacementId}-${ligne.articleId}`}><td><strong>{ligne.nomEmplacement}</strong><small>{ligne.nomRack} · Niveau {ligne.numeroEtage}</small></td><td><strong>{ligne.nomArticle}</strong></td><td>{ligne.quantiteTheorique}</td><td>{ligne.quantiteComptee}</td><td className={resultat.classe}>{ligne.ecart > 0 ? "+" : ""}{ligne.ecart}</td><td><span className={`rapport-resultat ${resultat.classe}`}><i />{resultat.libelle}</span></td></tr>;
                })}
              </tbody></table></div>}
            </section>

            <aside className="rapport-side">
              <section className="rapport-panel rapport-conclusion"><header className="rapport-panel-head"><h2>Conclusion</h2></header><div>{ecartTotal === 0 ? <p>Tous les emplacements contrôlés correspondent au stock théorique.</p> : <p>{lignesManquantes.length + lignesSurplus.length} écart{lignesManquantes.length + lignesSurplus.length > 1 ? "s" : ""} ont été constatés pour un total de {ecartTotal} pièce{ecartTotal > 1 ? "s" : ""} à examiner.</p>}<small>Ce rapport constate les écarts. Il ne modifie pas automatiquement le stock.</small></div></section>
              <section className="rapport-panel"><header className="rapport-panel-head"><div><h2>Participants</h2><p>Traçabilité du comptage</p></div><span className="rapport-panel-note">{participants.length}</span></header><div className="rapport-participants">
                {participants.length === 0 ? <p>Aucun participant enregistré.</p> : participants.map((participant) => <div className="rapport-participant" key={participant.participationId}><span>{participant.username?.slice(0, 2).toUpperCase()}</span><div><strong>{participant.username}</strong><small>{participant.matricule}</small></div><em>{participant.statut}</em></div>)}
              </div></section>
            </aside>
          </section>

          <footer className="rapport-footer"><p>Rapport généré le {dateEdition}. Toute régularisation doit suivre la procédure interne de l’entreprise.</p><Link to="/inventaires">Retour aux inventaires</Link></footer>
        </main>
      </section>
    </div>
  );
}

export default Recapitulatif;
