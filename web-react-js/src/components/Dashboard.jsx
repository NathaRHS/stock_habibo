import JournalTable from "./JournalTable";
import MovementChart from "./MovementChart";
import StockStatusCard from "./StockStatusCard";

function Dashboard() {
  return (
    <div className="dashboard-details">
      <div className="analytics-grid">
        <MovementChart />
        <StockStatusCard />
      </div>
      <JournalTable />
    </div>
  );
}

export default Dashboard;
