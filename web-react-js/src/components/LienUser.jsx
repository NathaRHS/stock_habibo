import { Link } from "react-router-dom";
import AvatarUtilisateur from "./AvatarUtilisateur";
import "./LienUser.css";

/**
 * Lien vers le profil d'un utilisateur. Avec `avecPhoto`, sa photo de profil
 * (ou ses initiales) s'affiche avant son nom.
 */
function LienUser({ userId, nom, photoUrl, avecPhoto = false, className = "" }) {
  const libelle = nom || "Utilisateur";
  const classes = `lien-user ${avecPhoto ? "lien-user--photo" : ""} ${className}`.trim();
  const id = Number(userId);
  const avatar = avecPhoto ? (
    <AvatarUtilisateur nom={libelle} photoUrl={photoUrl} taille={26} />
  ) : null;

  if (!Number.isInteger(id) || id <= 0) {
    return (
      <span className={`${classes} lien-user--indisponible`}>
        {avatar}
        {libelle}
      </span>
    );
  }

  return (
    <Link className={classes} to={`/user/${id}`} title={`Voir le profil de ${libelle}`}>
      {avatar}
      {libelle}
    </Link>
  );
}

export default LienUser;
