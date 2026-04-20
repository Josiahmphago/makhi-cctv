import { useState } from "react";
import PatrolDashboard from "./pages/PatrolDashboard";
import EscortPage from "./pages/EscortPage";
import BreakdownPage from "./pages/BreakdownPage";
import PolicePage from "./pages/PolicePage";
import AlertsPage from "./pages/AlertsPage";
import AgentsPage from "./pages/AgentsPage";
import "./index.css";

const tabs = ["Patrol","Escort","Breakdown","Police","Alerts","Agents"] as const;
type Tab = typeof tabs[number];

export default function App() {
  const [tab, setTab] = useState<Tab>("Patrol");

  return (
    <div className="page">
      <h1>Makhi CCTV — Console</h1>
      <div className="row" style={{gap:8, flexWrap:"wrap"}}>
        {tabs.map(t => (
          <button
            key={t}
            onClick={()=>setTab(t)}
            style={{background: t===tab ? "#eef6ff" : "#fafafa"}}
          >
            {t}
          </button>
        ))}
      </div>

      <div style={{marginTop:12}}>
        {tab==="Patrol" && <PatrolDashboard />}
        {tab==="Escort" && <EscortPage />}
        {tab==="Breakdown" && <BreakdownPage />}
        {tab==="Police" && <PolicePage />}
        {tab==="Alerts" && <AlertsPage />}
        {tab==="Agents" && <AgentsPage />}
      </div>
    </div>
  );
}
