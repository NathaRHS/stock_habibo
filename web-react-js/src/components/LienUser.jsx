import { Link } from "react-router-dom";
import "./LienUser.css";

function LienUser({ userId, nom, className = "" }) {
  const libelle = nom || "Utilisateur";
  const classes = `lien-user ${className}`.trim();
  const id = Number(userId);

  if (!Number.isInteger(id) || id <= 0) {
    return <span className={`${classes} lien-user--indisponible`}>{libelle}</span>;
  }

  return (
    <Link className={classes} to={`/user/${id}`} title={`Voir le profil de ${libelle}`}>
      {libelle}
    </Link>
  );
}

export default LienUser;
