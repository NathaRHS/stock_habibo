import { useEffect, useRef, useState } from "react";
import * as pdfjsLib from "pdfjs-dist/build/pdf.mjs";
import pdfWorker from "pdfjs-dist/build/pdf.worker.min.mjs?url";
import "./PdfViewer.css";

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorker;

function PdfViewer({ fichier, urlTelechargement, nomFichier }) {
  const viewerRef = useRef(null);
  const canvasRef = useRef(null);
  const pdfRef = useRef(null);
  const renduRef = useRef(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(0);
  const [zoom, setZoom] = useState(1);
  const [adapterLargeur, setAdapterLargeur] = useState(true);
  const [chargement, setChargement] = useState(true);
  const [erreur, setErreur] = useState("");

  useEffect(() => {
    let actif = true;
    let tache;

    async function chargerPdf() {
      try {
        const donnees = new Uint8Array(await fichier.arrayBuffer());
        if (!actif) return;

        tache = pdfjsLib.getDocument({ data: donnees });
        const pdf = await tache.promise;
        if (!actif) return;
        pdfRef.current = pdf;
        setTotalPages(pdf.numPages);
        setPage(1);
      } catch (cause) {
        console.error("Erreur de chargement PDF.js :", cause);
        if (actif) setErreur("Le document PDF ne peut pas être affiché.");
      } finally {
        if (actif) setChargement(false);
      }
    }

    chargerPdf();

    return () => {
      actif = false;
      renduRef.current?.cancel();
      tache?.destroy();
      pdfRef.current = null;
    };
  }, [fichier]);

  useEffect(() => {
    let actif = true;

    async function afficherPage() {
      const pdf = pdfRef.current;
      const canvas = canvasRef.current;
      const viewer = viewerRef.current;
      if (!pdf || !canvas || !viewer) return;

      try {
        renduRef.current?.cancel();
        const pagePdf = await pdf.getPage(page);
        const vueInitiale = pagePdf.getViewport({ scale: 1 });
        const largeurDisponible = Math.max(viewer.clientWidth - 48, 280);
        const echelle = adapterLargeur
          ? largeurDisponible / vueInitiale.width
          : zoom;
        const vue = pagePdf.getViewport({ scale: echelle });
        const ratio = window.devicePixelRatio || 1;
        const contexte = canvas.getContext("2d");

        canvas.width = Math.floor(vue.width * ratio);
        canvas.height = Math.floor(vue.height * ratio);
        canvas.style.width = `${Math.floor(vue.width)}px`;
        canvas.style.height = `${Math.floor(vue.height)}px`;

        const rendu = pagePdf.render({
          canvasContext: contexte,
          viewport: vue,
          transform: ratio === 1 ? null : [ratio, 0, 0, ratio, 0, 0],
        });
        renduRef.current = rendu;
        await rendu.promise;
      } catch (cause) {
        if (actif && cause?.name !== "RenderingCancelledException") {
          setErreur("Cette page du PDF ne peut pas être affichée.");
        }
      }
    }

    afficherPage();
    return () => {
      actif = false;
      renduRef.current?.cancel();
    };
  }, [page, totalPages, zoom, adapterLargeur]);

  function changerZoom(valeur) {
    setAdapterLargeur(false);
    setZoom(Math.min(Math.max(valeur, 0.5), 2.5));
  }

  async function basculerPleinEcran() {
    if (document.fullscreenElement) await document.exitFullscreen();
    else await viewerRef.current?.requestFullscreen();
  }

  return (
    <div className="pdf-viewer" ref={viewerRef}>
      <div className="pdf-toolbar">
        <div className="pdf-toolbar-group">
          <PdfTool
            icon="chevron_left"
            label="Page précédente"
            disabled={page <= 1}
            onClick={() => setPage((numero) => Math.max(numero - 1, 1))}
          />
          <span className="pdf-page-number">
            {page} / {totalPages || "—"}
          </span>
          <PdfTool
            icon="chevron_right"
            label="Page suivante"
            disabled={!totalPages || page >= totalPages}
            onClick={() => setPage((numero) => Math.min(numero + 1, totalPages))}
          />
        </div>

        <div className="pdf-toolbar-group">
          <PdfTool icon="remove" label="Réduire" onClick={() => changerZoom(zoom - 0.15)} />
          <button
            className={adapterLargeur ? "pdf-tool-active" : ""}
            type="button"
            onClick={() => setAdapterLargeur(true)}
            title="Ajuster à la largeur"
          >
            {adapterLargeur ? "Largeur" : `${Math.round(zoom * 100)} %`}
          </button>
          <PdfTool icon="add" label="Agrandir" onClick={() => changerZoom(zoom + 0.15)} />
        </div>

        <div className="pdf-toolbar-group">
          <a href={urlTelechargement} download={nomFichier} title="Télécharger">
            <span className="material-symbols-outlined">download</span>
          </a>
          <PdfTool icon="fullscreen" label="Plein écran" onClick={basculerPleinEcran} />
        </div>
      </div>

      <div className="pdf-canvas-area">
        {chargement && <p className="pdf-message">Chargement du PDF…</p>}
        {erreur && <p className="pdf-message pdf-message-error">{erreur}</p>}
        <canvas ref={canvasRef} hidden={chargement || Boolean(erreur)} />
      </div>
    </div>
  );
}

function PdfTool({ icon, label, ...props }) {
  return (
    <button type="button" aria-label={label} title={label} {...props}>
      <span className="material-symbols-outlined">{icon}</span>
    </button>
  );
}

export default PdfViewer;
