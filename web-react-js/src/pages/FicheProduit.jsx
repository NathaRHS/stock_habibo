import { useEffect, useState } from "react";
import {getFicheProduit} from "../services/ArticleService"
import { useParams } from "react-router-dom";
import RackView from "./Rackview";
import NewRackview from "../new-pages/rackview/NewRackView";


function FicheProduit() {
    
    const[donnees,setDonnees] = useState();
  const springUrl = import.meta.env.VITE_SPRING_URL;
  const {id} = useParams();


useEffect(() =>  {
    const chargerDonnees = async() => {
        const reponse = await getFicheProduit(springUrl,id);
        const data =  await reponse.json();

        setDonnees(data);

    }
    chargerDonnees();

},[])

    return(
        <>
        <p>fiche produit</p>
        <NewRackview></NewRackview>
            <p>{donnees?.nombreMouvement.totalEntrees}</p>
        </>
    )
}
export default FicheProduit;