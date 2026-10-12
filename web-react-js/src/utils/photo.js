export const PHOTO_TAILLE_MAX = 2 * 1024 * 1024; // 2 Mo, comme le serveur
const TYPES_ACCEPTES = ["image/jpeg", "image/png", "image/webp"];

/** Adresse complete d'une photo d'article (photoUrl vaut « photos/nom.jpg »). */
export const urlPhoto = (photoUrl) =>
  photoUrl ? `${import.meta.env.VITE_SPRING_URL}/${photoUrl}` : null;

/** Retourne un message d'erreur, ou une chaine vide si la photo est acceptable. */
export function verifierPhoto(fichier) {
  if (!fichier) return "";
  if (!TYPES_ACCEPTES.includes(fichier.type)) {
    return "Formats acceptés : JPG, PNG ou WebP.";
  }
  if (fichier.size > PHOTO_TAILLE_MAX) {
    return "La photo dépasse 2 Mo.";
  }
  return "";
}
