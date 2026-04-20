// src/components/AppNav.tsx
import React from "react";
import { Shield, CarFront, Wrench } from "lucide-react";

type Tab = "patrol" | "escort" | "breakdown";

export default function AppNav({
  current,
  onChange,
}: {
  current: Tab;
  onChange: (t: Tab) => void;
}) {
  return (
    <nav className="app-nav">
      <button
        className={`nav-btn ${current === "patrol" ? "active" : ""}`}
        onClick={() => onChange("patrol")}
      >
        <Shield size={22} />
        <span>Patrol</span>
      </button>

      <button
        className={`nav-btn ${current === "escort" ? "active" : ""}`}
        onClick={() => onChange("escort")}
      >
        <CarFront size={22} />
        <span>Escort</span>
      </button>

      <button
        className={`nav-btn ${current === "breakdown" ? "active" : ""}`}
        onClick={() => onChange("breakdown")}
      >
        <Wrench size={22} />
        <span>Breakdown</span>
      </button>
    </nav>
  );
}
