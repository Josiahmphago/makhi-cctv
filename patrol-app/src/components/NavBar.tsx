import { Shield, Car, Wrench } from "lucide-react";

type Props = {
  current: "patrol" | "escort" | "breakdown";
  onChange: (tab: Props["current"]) => void;
};

export default function NavBar({ current, onChange }: Props) {
  const Item = ({
    id,
    label,
    Icon,
  }: { id: Props["current"]; label: string; Icon: any }) => (
    <button
      onClick={() => onChange(id)}
      className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg ${
        current === id ? "bg-blue-600 text-white" : "bg-white border hover:bg-gray-50"
      }`}
    >
      <Icon size={18} />
      {label}
    </button>
  );

  return (
    <div className="sticky top-0 z-40 bg-gray-50/80 backdrop-blur border-b">
      <div className="max-w-6xl mx-auto p-3 flex gap-2">
        <Item id="patrol" label="Patrol" Icon={Shield} />
        <Item id="escort" label="Escort" Icon={Car} />
        <Item id="breakdown" label="Breakdown" Icon={Wrench} />
      </div>
    </div>
  );
}
