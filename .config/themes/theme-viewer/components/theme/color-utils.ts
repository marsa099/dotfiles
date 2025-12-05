import { HSL, ColorTheme } from './types';

export function hexToHsl(hex: string): HSL {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }

  return { h: h * 360, s: s * 100, l: l * 100 };
}

export function hslToHex(h: number, s: number, l: number): string {
  h /= 360;
  s /= 100;
  l /= 100;

  const hue2rgb = (p: number, q: number, t: number) => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };

  if (s === 0) {
    const grey = Math.round(l * 255);
    return `#${grey.toString(16).padStart(2, "0").repeat(3)}`;
  }

  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const r = Math.round(hue2rgb(p, q, h + 1 / 3) * 255);
  const g = Math.round(hue2rgb(p, q, h) * 255);
  const b = Math.round(hue2rgb(p, q, h - 1 / 3) * 255);

  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

export function resolveColor(colorValue: string, theme: any): string {
  if (colorValue.startsWith("#")) {
    return colorValue;
  }

  const parts = colorValue.split(".");
  if (parts.length === 2) {
    const [category, name] = parts;
    return theme[category]?.[name] || colorValue;
  }

  return colorValue;
}

export function createResolvedTheme(rawTheme: any): ColorTheme {
  const resolved = JSON.parse(JSON.stringify(rawTheme));

  // Resolve semantic colors
  if (resolved.semantic) {
    for (const [key, value] of Object.entries(resolved.semantic)) {
      if (typeof value === "string") {
        resolved.semantic[key] = resolveColor(value as string, rawTheme);
      }
    }
  }

  // Resolve terminal colors
  if (resolved.terminal) {
    for (const [key, value] of Object.entries(resolved.terminal)) {
      if (typeof value === "string") {
        resolved.terminal[key] = resolveColor(value as string, rawTheme);
      }
    }
  }

  return resolved;
}