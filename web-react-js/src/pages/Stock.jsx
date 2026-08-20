import { useEffect } from "react";

function Emplacement() {

    const springUrl = import.meta.env.VITE_SPRING_URL;
      const [societes, setSocietes] = useState([]);
      const [error, setError] = useState("");
      const [loading, setLoading] = useState(true);

      useEffect(()=>{
        const getListeEmplacementTotal = () => {
            try {
                const response = await fetch(`${springUrl} + /getListeEmplacementTotal`);
                const data = response.json();
                console.log(data)
                
            } catch (error) {
                
            }
            
        }
      })
    return(
        <>
            <p>Schéma de l'emplacement dans l'entrepôt</p>
            <div className="entrepot-schema">

            </div>
        </>
    )
}