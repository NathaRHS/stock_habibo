import { useState } from "react";
import { Package } from "lucide-react";
import { urlPhoto } from "../utils/photo";
import "./VignetteArticle.css";

/** Photo d'un article en petit format, ou une icone neutre s'il n'y en a pas. */
function VignetteArticle({ photoUrl, nom = "", taille = 40 }) {
  const [enErreur, setEnErreur] = useState(false);
  const source = urlPhoto(photoUrl);

  return (
    <span className="vignette-article" style={{ width: taille, height: taille }}>
      {source && !enErreur ? (
        <img
          src={source}
          alt={nom}
          loading="lazy"
          onError={() => setEnErreur(true)}
        />
      ) : (
        <Package size={Math.round(taille / 2)} aria-hidden="true" />
      )}
    </span>
  );
}

export default VignetteArticle;
