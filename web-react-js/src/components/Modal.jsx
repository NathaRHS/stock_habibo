import { useEffect, useId, useRef } from "react";
import { createPortal } from "react-dom";
import "./Modal.css";

function Modal({
  ouverte,
  titre,
  children,
  actions,
  fermetureAutorisee = true,
  onClose,
}) {
  const titreId = useId();
  const dialogueRef = useRef(null);

  useEffect(() => {
    if (!ouverte) return undefined;

    const elementPrecedemmentActif = document.activeElement;
    const ancienOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    dialogueRef.current?.focus();

    const gererTouche = (event) => {
      if (event.key === "Escape" && fermetureAutorisee) {
        onClose?.();
      }
    };

    document.addEventListener("keydown", gererTouche);

    return () => {
      document.removeEventListener("keydown", gererTouche);
      document.body.style.overflow = ancienOverflow;
      elementPrecedemmentActif?.focus?.();
    };
  }, [ouverte, fermetureAutorisee, onClose]);

  if (!ouverte) return null;

  const gererClicFond = (event) => {
    if (event.target === event.currentTarget && fermetureAutorisee) {
      onClose?.();
    }
  };

  return createPortal(
    <div className="modal-backdrop" onMouseDown={gererClicFond}>
      <section
        ref={dialogueRef}
        className="modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titreId}
        tabIndex="-1"
      >
        <header className="modal-header">
          <h2 id={titreId}>{titre}</h2>

          {fermetureAutorisee && (
            <button
              type="button"
              className="modal-close"
              aria-label="Fermer la fenetre"
              onClick={onClose}
            >
              x
            </button>
          )}
        </header>

        <div className="modal-content">{children}</div>

        {actions && <footer className="modal-actions">{actions}</footer>}
      </section>
    </div>,
    document.body,
  );
}

export default Modal;
