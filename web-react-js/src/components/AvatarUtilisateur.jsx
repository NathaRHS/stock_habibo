import { useState } from "react";
import { urlPhoto } from "../utils/photo";
import "./AvatarUtilisateur.css";

const initiales = (nom) =>
  String(nom ?? "?")
    .replace(/[^A-Za-zÀ-ÿ0-9 ]/g, " ")
    .trim()
    .slice(0, 2)
    .toUpperCase() || "?";

/** Photo de profil en petit rond, ou les initiales si elle n'existe pas. */
function AvatarUtilisateur({ nom, photoUrl, taille = 28 }) {
  const [enErreur, setEnErreur] = useState(false);
  const source = urlPhoto(photoUrl);

  return (
    <span
      className="avatar-utilisateur"
      style={{ width: taille, height: taille, fontSize: Math.round(taille * 0.36) }}
    >
      {source && !enErreur ? (
        <img
          alt=""
          loading="lazy"
          onError={() => setEnErreur(true)}
          src={source}
        />
      ) : (
        <span aria-hidden="true">{initiales(nom)}</span>
      )}
    </span>
  );
}

export default AvatarUtilisateur;
