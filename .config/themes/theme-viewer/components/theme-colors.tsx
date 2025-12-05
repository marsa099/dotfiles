"use client";

import { useEffect, useState } from "react";
import { ThemeToggle } from "./theme-toggle";
import { CodePreview } from "./theme/CodePreview";
import { ColorPicker } from "./theme/ColorPicker";
import { ColorGrid } from "./theme/ColorGrid";
import { SaveChanges } from "./theme/SaveChanges";
import { ThemeData, ColorTheme, ColorPickerState } from "./theme/types";
import {
  hexToHsl,
  resolveColor,
  createResolvedTheme,
} from "./theme/color-utils";

export function ThemeColors() {
  const [themeData, setThemeData] = useState<ThemeData | null>(null);
  const [rawThemeData, setRawThemeData] = useState<any>(null);
  const [currentMode, setCurrentMode] = useState<"dark" | "light">("dark");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [colorPicker, setColorPicker] = useState<ColorPickerState | null>(null);
  const [previewTheme, setPreviewTheme] = useState<ColorTheme | null>(null);
  const [hasChanges, setHasChanges] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [selectedAccent, setSelectedAccent] = useState<string | null>(null);

  const loadTheme = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/theme");
      if (!response.ok) throw new Error("Failed to load theme");
      const data = await response.json();
      setRawThemeData(data);

      const resolvedData = {
        ...data,
        themes: {
          dark: createResolvedTheme(data.themes.dark),
          light: createResolvedTheme(data.themes.light),
        },
      };
      setThemeData(resolvedData);
      setPreviewTheme(null);
      setHasChanges(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load theme");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const initializeTheme = async () => {
      await loadTheme();
      const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      setCurrentMode(isDark ? "dark" : "light");
    };

    initializeTheme();

    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    const handleChange = (e: MediaQueryListEvent) =>
      setCurrentMode(e.matches ? "dark" : "light");
    mediaQuery.addEventListener("change", handleChange);

    return () => {
      mediaQuery.removeEventListener("change", handleChange);
    };
  }, []);

  const getSemanticColorsUsingAccent = (accentName: string) => {
    if (!rawThemeData) return [];
    const semanticColors: string[] = [];
    const accentRef = `accent.${accentName}`;

    for (const [key, value] of Object.entries(
      rawThemeData.themes[currentMode].semantic,
    )) {
      if (value === accentRef) {
        semanticColors.push(key);
      }
    }

    return semanticColors;
  };

  const handleColorClick = (category: string, name: string, color: string) => {
    if (!rawThemeData) return;

    const hsl = hexToHsl(color);
    let mappedTo: string | undefined;

    // Check raw theme data for ALL categories to see if they have mappings
    const rawValue = rawThemeData.themes[currentMode][category]?.[name];

    if (rawValue && typeof rawValue === "string" && !rawValue.startsWith("#")) {
      // This is a mapped color (e.g., "accent.blue")
      mappedTo = rawValue;
    }

    setColorPicker({
      isOpen: true,
      originalColor: color,
      currentColor: color,
      hsl,
      category,
      name,
      position: { x: 0, y: 0 },
      mappedTo,
    });

    // Clear selected accent when opening color picker
    setSelectedAccent(null);
  };

  const handleColorChange = (category: string, name: string, color: string) => {
    if (!themeData || !rawThemeData) return;

    const newRawData = JSON.parse(JSON.stringify(rawThemeData));
    if (
      typeof newRawData.themes[currentMode][category as keyof ColorTheme] ===
      "object"
    ) {
      (
        newRawData.themes[currentMode][category as keyof ColorTheme] as Record<
          string,
          string
        >
      )[name] = color;
    } else if (category === "cursor") {
      newRawData.themes[currentMode].cursor = color;
    }

    // Save the updated raw data
    setRawThemeData(newRawData);

    const newTheme = createResolvedTheme(newRawData.themes[currentMode]);
    setPreviewTheme(newTheme);
    setHasChanges(true);
  };

  const handleSemanticMapping = (
    semanticCategory: string,
    semanticName: string,
    newMapping: string,
  ) => {
    if (!rawThemeData || !themeData) return;

    // Update the raw theme data with the new mapping
    const newRawData = JSON.parse(JSON.stringify(rawThemeData));
    newRawData.themes[currentMode].semantic[semanticName] = newMapping;

    // Save the updated raw data
    setRawThemeData(newRawData);

    // Resolve the new color value
    const resolvedColor = resolveColor(
      newMapping,
      newRawData.themes[currentMode],
    );

    // Create a new preview theme with the resolved color
    const newTheme = previewTheme
      ? { ...previewTheme }
      : { ...themeData.themes[currentMode] };
    (newTheme.semantic as Record<string, string>)[semanticName] = resolvedColor;

    setPreviewTheme(newTheme);
    setHasChanges(true);
  };

  const saveChanges = async () => {
    if (!hasChanges || !previewTheme || !rawThemeData) return;

    setIsSaving(true);
    try {
      // Use the raw theme data which contains the mappings
      const themeToSave = rawThemeData.themes[currentMode];

      const response = await fetch("/api/theme/save", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          themeData: themeToSave,
          mode: currentMode,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to save theme");
      }

      const result = await response.json();
      console.log("Theme changes saved!", result);
      setHasChanges(false);

      // Reload the theme to ensure consistency
      await loadTheme();

      if (result.warning) {
        console.warn("Theme saved with warning:", result.warning);
      }
    } catch (error) {
      console.error("Failed to save theme changes:", error);
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{ backgroundColor: "#0F0F0F" }}
      >
        <div className="text-white">Loading theme...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{ backgroundColor: "#0F0F0F" }}
      >
        <div className="text-red-500">Error: {error}</div>
      </div>
    );
  }

  if (!themeData || !themeData.themes || !themeData.themes[currentMode]) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{ backgroundColor: "#0F0F0F" }}
      >
        <div className="text-white">No theme data available</div>
      </div>
    );
  }

  const theme = previewTheme || themeData.themes[currentMode];

  return (
    <div
      className="min-h-screen transition-colors duration-500"
      style={{
        backgroundColor:
          currentMode === "dark" ? "#0F0F0F" : theme.background.secondary,
        color: theme.foreground.primary,
      }}
    >
      <div className="fixed top-6 right-6 z-50">
        <ThemeToggle
          currentMode={currentMode}
          onToggle={() =>
            setCurrentMode(currentMode === "dark" ? "light" : "dark")
          }
        />
      </div>

      <div className="max-w-7xl mx-auto px-6 py-18">
        <div
          className="rounded-2xl shadow-xl overflow-hidden mb-12"
          style={{
            backgroundColor: theme.background.primary,
            boxShadow: `0 20px 25px -5px ${theme.background.overlay}20, 0 10px 10px -5px ${theme.background.overlay}10`,
          }}
        >
          <div
            className="py-8 px-6"
            style={{
              backgroundColor: theme.background.secondary,
              borderBottom: `1px solid ${theme.background.overlay}`,
            }}
          >
            <h2 className="text-2xl font-semibold mb-2">Code Preview</h2>
            <p style={{ color: theme.foreground.secondary }}>
              Click any color to edit it
            </p>
          </div>
          <CodePreview theme={theme} onColorClick={handleColorClick} />
        </div>

        <ColorGrid
          theme={theme}
          rawThemeData={rawThemeData}
          currentMode={currentMode}
          onColorClick={handleColorClick}
          selectedAccent={selectedAccent}
          getSemanticColorsUsingAccent={getSemanticColorsUsingAccent}
        />

        <SaveChanges
          hasChanges={hasChanges}
          isSaving={isSaving}
          theme={theme}
          onSave={saveChanges}
        />
      </div>

      <ColorPicker
        colorPicker={colorPicker}
        setColorPicker={setColorPicker}
        onColorChange={handleColorChange}
        onSemanticMapping={handleSemanticMapping}
        theme={theme}
        rawThemeData={rawThemeData}
        currentMode={currentMode}
        isDarkMode={currentMode === "dark"}
      />
    </div>
  );
}
