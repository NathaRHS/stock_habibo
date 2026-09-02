import { useEffect, useState } from "react";
import { getAccessToken } from "../services/authService";

function Inventaire() {
  //prendre la liste des journaux mouvements
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const [journaux, setJournaux] = useState([]);
  const token = getAccessToken();
  const [journalSelectionne, setJournalSelectionne] = useState(null);

  const journauxInventaire = journaux.filter(
    (jr) => jr.typeMouvementJournal === "INVENTAIRE",
  );

  const rechercher = async() => {
    const response = await fetch(`${springUrl}/inventaire/${journalSelectionne}`, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
        console.log(data);
  }

  useEffect(() => {
    const getJournaux = async () => {
      const response = await fetch(`${springUrl}/journaux-mouvements`, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      });
      const data = await response.json();
      console.log(data);
      setJournaux(data);
    };
    getJournaux();
  }, []);

  return (
    <div>
      <select
        onChange={(e) => setJournalSelectionne(e.target.value)}
        name=""
        id=""
      >
        {journauxInventaire?.map((jr, index) => {
          return (
            <option value={jr.id}>{index + 1 + " - " + jr.reference}</option>
          );
        })}
      </select>
      <button onClick={() => rechercher()}>a</button>

      <div>{journalSelectionne}</div>
    </div>
  );
}
export default Inventaire;
