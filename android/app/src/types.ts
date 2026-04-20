export type CameraDoc = {
  name: string;
  ipAddress: string;       // e.g. "192.168.18.25"
  area?: string;
  location?: string;
  isActive?: boolean;
  patrolTeamId?: string;
  ownerName?: string;
  ownerContact?: string;
  type?: "street" | "gate" | "yard" | string;
};
