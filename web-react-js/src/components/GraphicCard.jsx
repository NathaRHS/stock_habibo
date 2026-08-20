import "../assets/css/GraphicCard.css";

function GraphicCard({
  designation,
  valeur_chiffres,
  valeur_hier,
  valeur_now,
  props_color,
  icon,
}) {
  const difference = valeur_now - valeur_hier;
  const taux = valeur_hier === 0 ? 0 : (Math.abs(difference) * 100) / valeur_hier;
  const isNegative = difference < 0;

  return (
    <article className="graphic-card-container" style={{ background: props_color }}>
      <span className="graphic-card-icon material-symbols-outlined" aria-hidden="true">
        {icon}
      </span>
      <p className="graphic-card-title">{designation}</p>
      <p className="graphic-card-value">{valeur_chiffres.toLocaleString("fr-FR")}</p>
      <p className={`graphic-card-rate ${isNegative ? "graphic-card-rate--negative" : "graphic-card-rate--positive"}`}>
        {isNegative ? "−" : "+"}{taux.toFixed(1)}% par rapport à hier
      </p>
    </article>
  );
}

export default GraphicCard;
