import React from "react";
import { CctvCamera } from "../hooks/useCameras";

type Props = {
  cam: CctvCamera;
  onView?: (cam: CctvCamera) => void;
  onDeactivate?: (cam: CctvCamera) => void;
  onAlert?: (cam: CctvCamera) => void;
};

export default function CameraCard({ cam, onView, onDeactivate, onAlert }: Props) {
  return (
    <div className="card">
      <div className="row">
        <b>{cam.name}</b>
        <span>IP: {cam.ip || "—"}</span>
        <span>Loc: {cam.location || "—"}</span>
        <span>Status: {cam.status || "Active"}</span>
      </div>
      <div className="row">
        <button onClick={() => onView?.(cam)}>View (raw)</button>
        <button onClick={() => onAlert?.(cam)}>Alert</button>
        <button onClick={() => onDeactivate?.(cam)}>Deactivate</button>
      </div>
    </div>
  );
}
