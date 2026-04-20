// src/lib/camera.ts

export function buildStreamUrl(ipOrUrl?: string, explicit?: string) {
  if (explicit) return explicit;
  if (!ipOrUrl) return "";
  try {
    // If it's already a full URL, return it
    const u = new URL(ipOrUrl);
    return u.toString();
  } catch {
    // Heuristic for ESP32-CAM defaults:
    // - MJPEG stream usually on :81/stream
    // - Still capture usually at /capture on port 80
    const ip = ipOrUrl.trim();
    return `http://${ip}:81/stream`;
  }
}

export function buildCaptureUrl(ipOrUrl?: string) {
  if (!ipOrUrl) return "";
  try {
    const u = new URL(ipOrUrl);
    // If they passed full URL for capture, just use it
    return u.toString();
  } catch {
    const ip = ipOrUrl.trim();
    return `http://${ip}/capture`;
  }
}

export async function captureJpegBlob(ipOrUrl?: string) {
  const url = buildCaptureUrl(ipOrUrl);
  if (!url) throw new Error("No capture URL");
  const res = await fetch(url, { cache: "no-cache" });
  if (!res.ok) throw new Error(`Capture failed (${res.status})`);
  const blob = await res.blob();
  if (blob.type !== "image/jpeg" && blob.type !== "image/jpg") {
    // Some firmwares send octet-stream; still fine
  }
  return blob;
}
