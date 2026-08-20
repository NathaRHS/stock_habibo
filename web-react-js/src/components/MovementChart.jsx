import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import "../assets/css/Dashboard.css";

const movements = [
  { jour: "Lun", entrees: 82, sorties: 64 },
  { jour: "Mar", entrees: 68, sorties: 91 },
  { jour: "Mer", entrees: 112, sorties: 73 },
  { jour: "Jeu", entrees: 94, sorties: 58 },
  { jour: "Ven", entrees: 121, sorties: 84 },
  { jour: "Sam", entrees: 76, sorties: 69 },
  { jour: "Dim", entrees: 98, sorties: 88 },
];

function MovementChart() {
  return (
    <section className="movement-chart" aria-labelledby="movement-chart-title">
      <div className="chart-header">
        <div>
          <h2 id="movement-chart-title">Évolution des mouvements</h2>
          <div className="chart-legend" aria-label="Légende">
            <span><i className="legend-dot legend-dot--entry" />Entrées</span>
            <span><i className="legend-dot legend-dot--exit" />Sorties</span>
          </div>
        </div>
        <select aria-label="Période du graphique" defaultValue="week">
          <option value="week">Cette semaine</option>
          <option value="month">Ce mois</option>
          <option value="year">Cette année</option>
        </select>
      </div>

      <div className="chart-canvas">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={movements} margin={{ top: 12, right: 12, bottom: 0, left: -20 }}>
            <CartesianGrid stroke="var(--color-border)" strokeDasharray="3 5" vertical={false} />
            <XAxis dataKey="jour" axisLine={false} tickLine={false} tick={{ fill: "var(--color-text-secondary)", fontSize: 11 }} />
            <YAxis axisLine={false} tickLine={false} tick={{ fill: "var(--color-text-secondary)", fontSize: 11 }} />
            <Tooltip contentStyle={{ border: "1px solid var(--color-border)", borderRadius: "8px", boxShadow: "0 8px 24px rgb(65 83 100 / 12%)" }} />
            <Line type="monotone" dataKey="entrees" name="Entrées" stroke="var(--color-primary)" strokeWidth={2.5} dot={false} activeDot={{ r: 5 }} />
            <Line type="monotone" dataKey="sorties" name="Sorties" stroke="var(--color-secondary)" strokeWidth={2.5} dot={false} activeDot={{ r: 5 }} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}

export default MovementChart;
