export interface ColorTheme {
  background: Record<string, string>;
  foreground: Record<string, string>;
  accent: Record<string, string>;
  semantic: Record<string, string>;
  terminal: Record<string, string>;
}

export interface ThemeData {
  themes: {
    dark: ColorTheme;
    light: ColorTheme;
  };
}

export interface HSL {
  h: number;
  s: number;
  l: number;
}

export interface ColorPickerState {
  isOpen: boolean;
  originalColor: string;
  currentColor: string;
  hsl: HSL;
  category: string;
  name: string;
  position: { x: number; y: number };
  mappedTo?: string;
}