import ListeSociete from "./ListeSociete";
import { useState } from "react";
function CrudElement() {
  const [Choix, setChoix] = useState("");
  return (
    <div className="crud-container">
      <button
        type="button"
        value="societe"
        onClick={() => setChoix("Sociétés")}
      >
        Sociétés
      </button>

      {Choix === "Sociétés" ? <ListeSociete /> : ""}
    </div>
  );
}

export default CrudElement;
