// src/lib/cameraUrl.ts
export function buildSnapshotUrl(ip?: string) {
  if (!ip) return "";
  // Use /capture for single JPEG (your ESP32 sketches expose /capture most of the time)
  return `http://${ip}/capture`;
}

export function buildStreamUrl(ip?: string) {
  if (!ip) return "";
  // MJPEG stream path (most ESP32-CAM sketches export /stream)
  return `http://${ip}/stream`;
}
