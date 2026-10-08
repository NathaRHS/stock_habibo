import { Check } from "lucide-react";
import "./CreateArticleModal.css";

/**
 * Indicateur d'etapes : fait (coche), en cours (accent bleu), a venir (gris).
 * etapeCourante commence a 1.
 */
function StepperArticle({ etapes, etapeCourante }) {
  return (
    <ol className="stepper-article" aria-label="Progression de la creation">
      {etapes.map((libelle, index) => {
        const numero = index + 1;
        const etat =
          numero < etapeCourante
            ? "fait"
            : numero === etapeCourante
              ? "courante"
              : "a-venir";

        return (
          <li
            key={libelle}
            className={`stepper-article-etape stepper-article-etape--${etat}`}
            aria-current={etat === "courante" ? "step" : undefined}
          >
            <span className="stepper-article-pastille">
              {etat === "fait" ? <Check size={14} strokeWidth={3} /> : numero}
            </span>
            <span className="stepper-article-libelle">{libelle}</span>
          </li>
        );
      })}
    </ol>
  );
}

export default StepperArticle;
