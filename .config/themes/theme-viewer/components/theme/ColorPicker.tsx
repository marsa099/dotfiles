"use client";

import { useEffect, useState, useRef } from "react";
import { ColorTheme, ColorPickerState } from './types';
import { hexToHsl, hslToHex } from './color-utils';
import { ColorSlider } from './ColorSlider';

interface ColorPickerProps {
  colorPicker: ColorPickerState | null;
  setColorPicker: (state: ColorPickerState | null) => void;
  onColorChange: (category: string, name: string, color: string) => void;
  onSemanticMapping: (
    semanticCategory: string,
    semanticName: string,
    newMapping: string,
  ) => void;
  theme: ColorTheme;
  rawThemeData?: any;
  currentMode?: 'dark' | 'light';
  isDarkMode?: boolean;
}

export function ColorPicker({
  colorPicker,
  setColorPicker,
  onColorChange,
  onSemanticMapping,
  theme,
  rawThemeData,
  currentMode = 'dark',
  isDarkMode = false,
}: ColorPickerProps) {
  // Helper function to find semantic colors using this accent
  const getSemanticColorsUsingAccent = () => {
    if (colorPicker?.category !== 'accent' || !rawThemeData) return [];
    const semanticColors: string[] = [];
    const accentRef = `accent.${colorPicker.name}`;
    
    // Check raw theme data to find semantic colors mapped to this accent
    const semantics = rawThemeData.themes[currentMode].semantic;
    for (const [key, value] of Object.entries(semantics)) {
      if (value === accentRef) {
        semanticColors.push(key);
      }
    }
    
    return semanticColors;
  };
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const pickerRef = useRef<HTMLDivElement>(null);
  const [isDraggingHue, setIsDraggingHue] = useState(false);
  const [isDraggingSL, setIsDraggingSL] = useState(false);

  useEffect(() => {
    if (!colorPicker) return;

    const handleClickOutside = (event: MouseEvent) => {
      if (
        pickerRef.current &&
        !pickerRef.current.contains(event.target as Node)
      ) {
        setColorPicker(null);
      }
    };

    const handleEscKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setColorPicker(null);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleEscKey);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleEscKey);
    };
  }, [colorPicker, setColorPicker]);

  // Handle mouse up globally to stop dragging
  useEffect(() => {
    const handleMouseUp = () => {
      setIsDraggingHue(false);
      setIsDraggingSL(false);
    };

    document.addEventListener("mouseup", handleMouseUp);
    return () => {
      document.removeEventListener("mouseup", handleMouseUp);
    };
  }, []);

  useEffect(() => {
    if (!colorPicker || !canvasRef.current) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // Set up high DPI canvas for sharper rendering
    const dpr = window.devicePixelRatio || 1;
    const displayWidth = 250;
    const displayHeight = 250;
    
    canvas.width = displayWidth * dpr;
    canvas.height = displayHeight * dpr;
    canvas.style.width = `${displayWidth}px`;
    canvas.style.height = `${displayHeight}px`;
    
    ctx.scale(dpr, dpr);

    const centerX = displayWidth / 2;
    const centerY = displayHeight / 2;
    const radius = Math.min(centerX, centerY) - 10;

    ctx.clearRect(0, 0, displayWidth, displayHeight);

    // Draw hue circle
    for (let angle = 0; angle < 360; angle++) {
      const startAngle = (angle - 1) * (Math.PI / 180);
      const endAngle = angle * (Math.PI / 180);

      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, startAngle, endAngle);
      ctx.strokeStyle = `hsl(${angle}, 100%, 50%)`;
      ctx.lineWidth = 20;
      ctx.stroke();
    }

    // Draw saturation/lightness square
    const squareSize = radius * 0.7;
    const squareX = centerX - squareSize / 2;
    const squareY = centerY - squareSize / 2;

    // Create white to saturated color gradient (left to right)
    const saturationGradient = ctx.createLinearGradient(squareX, 0, squareX + squareSize, 0);
    saturationGradient.addColorStop(0, `hsl(${colorPicker.hsl.h}, 0%, 50%)`);
    saturationGradient.addColorStop(1, `hsl(${colorPicker.hsl.h}, 100%, 50%)`);
    
    // Fill with saturation gradient
    ctx.fillStyle = saturationGradient;
    ctx.fillRect(squareX, squareY, squareSize, squareSize);
    
    // Create lightness gradient (top to bottom) 
    const lightnessGradient = ctx.createLinearGradient(0, squareY, 0, squareY + squareSize);
    lightnessGradient.addColorStop(0, 'rgba(255, 255, 255, 1)');
    lightnessGradient.addColorStop(0.5, 'rgba(255, 255, 255, 0)');
    lightnessGradient.addColorStop(0.5, 'rgba(0, 0, 0, 0)');
    lightnessGradient.addColorStop(1, 'rgba(0, 0, 0, 1)');
    
    // Overlay lightness gradient
    ctx.fillStyle = lightnessGradient;
    ctx.fillRect(squareX, squareY, squareSize, squareSize);

    // Draw current color indicator on hue circle
    const hueAngle = (colorPicker.hsl.h * Math.PI) / 180;
    const hueX = centerX + Math.cos(hueAngle) * (radius - 10);
    const hueY = centerY + Math.sin(hueAngle) * (radius - 10);

    ctx.beginPath();
    ctx.arc(hueX, hueY, 8, 0, 2 * Math.PI);
    ctx.fillStyle = "white";
    ctx.fill();
    ctx.strokeStyle = "black";
    ctx.lineWidth = 2;
    ctx.stroke();

    // Draw saturation/lightness indicator
    const slX = squareX + (colorPicker.hsl.s / 100) * squareSize;
    const slY = squareY + ((100 - colorPicker.hsl.l) / 100) * squareSize;

    ctx.beginPath();
    ctx.arc(slX, slY, 6, 0, 2 * Math.PI);
    ctx.fillStyle = "white";
    ctx.fill();
    ctx.strokeStyle = "black";
    ctx.lineWidth = 2;
    ctx.stroke();
  }, [colorPicker]);

  const updateColorFromPosition = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!colorPicker || !canvasRef.current) return;

    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    // Use display dimensions, not canvas dimensions (which are scaled for DPI)
    const displayWidth = 250;
    const displayHeight = 250;
    const centerX = displayWidth / 2;
    const centerY = displayHeight / 2;
    const radius = Math.min(centerX, centerY) - 10;

    const distance = Math.sqrt((x - centerX) ** 2 + (y - centerY) ** 2);

    if ((isDraggingHue || !isDraggingSL) && distance > radius - 30 && distance < radius + 10) {
      // Hue selection
      const angle = Math.atan2(y - centerY, x - centerX) * (180 / Math.PI);
      const h = angle < 0 ? angle + 360 : angle;

      const newHsl = { ...colorPicker.hsl, h };
      const newColor = hslToHex(newHsl.h, newHsl.s, newHsl.l);

      setColorPicker({ ...colorPicker, hsl: newHsl, currentColor: newColor });
      onColorChange(colorPicker.category, colorPicker.name, newColor);
      return true;
    } else {
      // Saturation/Lightness selection
      const squareSize = radius * 0.7;
      const squareX = centerX - squareSize / 2;
      const squareY = centerY - squareSize / 2;

      if (
        (isDraggingSL || !isDraggingHue) &&
        x >= squareX &&
        x <= squareX + squareSize &&
        y >= squareY &&
        y <= squareY + squareSize
      ) {
        const s = Math.max(0, Math.min(100, ((x - squareX) / squareSize) * 100));
        const l = Math.max(0, Math.min(100, ((squareSize - (y - squareY)) / squareSize) * 100));

        const newHsl = { ...colorPicker.hsl, s, l };
        const newColor = hslToHex(newHsl.h, newHsl.s, newHsl.l);

        setColorPicker({ ...colorPicker, hsl: newHsl, currentColor: newColor });
        onColorChange(colorPicker.category, colorPicker.name, newColor);
        return true;
      }
    }
    return false;
  };

  const handleCanvasMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!colorPicker || !canvasRef.current) return;

    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    // Use display dimensions
    const displayWidth = 250;
    const displayHeight = 250;
    const centerX = displayWidth / 2;
    const centerY = displayHeight / 2;
    const radius = Math.min(centerX, centerY) - 10;
    const distance = Math.sqrt((x - centerX) ** 2 + (y - centerY) ** 2);

    if (distance > radius - 30 && distance < radius + 10) {
      setIsDraggingHue(true);
      updateColorFromPosition(e);
    } else {
      const squareSize = radius * 0.7;
      const squareX = centerX - squareSize / 2;
      const squareY = centerY - squareSize / 2;

      if (
        x >= squareX &&
        x <= squareX + squareSize &&
        y >= squareY &&
        y <= squareY + squareSize
      ) {
        setIsDraggingSL(true);
        updateColorFromPosition(e);
      }
    }
  };

  const handleCanvasMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (isDraggingHue || isDraggingSL) {
      updateColorFromPosition(e);
    }
  };

  if (!colorPicker) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center pointer-events-none">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 pointer-events-auto" onClick={() => setColorPicker(null)} />
      
      {/* Card */}
      <div
        ref={pickerRef}
        className="relative rounded-lg p-6 shadow-2xl border pointer-events-auto"
        style={{
          backgroundColor: theme.background.secondary,
          color: theme.foreground.primary,
          borderColor: theme.background.overlay,
          width: "700px",
          maxWidth: "90vw",
          maxHeight: "80vh",
          overflow: "auto",
        }}
      >
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <div>
            <h3 className="text-lg font-semibold">
              {colorPicker.category}.{colorPicker.name}
            </h3>
            {colorPicker.mappedTo && (
              <p className="text-sm opacity-75">
                Currently mapped to:{" "}
                <span className="font-mono">{colorPicker.mappedTo}</span>
              </p>
            )}
          </div>
          <button
            onClick={() => setColorPicker(null)}
            className="text-2xl hover:opacity-70 leading-none px-2"
          >
            ×
          </button>
        </div>

        {/* Show different UI based on whether it's a mapped color, direct color, or accent color */}
        {colorPicker.mappedTo && colorPicker.category !== 'accent' ? (
          // For mapped semantic colors - only show remapping options
          <div
            className="p-6 rounded border"
            style={{ borderColor: theme.background.overlay }}
          >
            <h4 className="font-semibold mb-3">Change Color Mapping</h4>
            <p className="text-sm opacity-75 mb-4">
              This semantic color is currently mapped to <span className="font-mono bg-black/10 px-2 py-1 rounded">{colorPicker.mappedTo}</span>
            </p>
            <div className="grid grid-cols-3 gap-2 max-h-80 overflow-y-auto">
              {Object.entries(theme).map(([category, colors]) => {
                // Only show accent colors in the mapping modal
                if (category === "accent" && typeof colors === "object" && colors !== null) {
                  return Object.entries(colors).map(([name, color]) => (
                    <button
                      key={`${category}.${name}`}
                      className={`flex items-center gap-2 p-2 rounded text-left hover:opacity-80 transition-all ${
                        colorPicker.mappedTo === `${category}.${name}`
                          ? "ring-2"
                          : ""
                      }`}
                      style={{
                        backgroundColor: theme.background.primary,
                        borderColor: theme.background.overlay,
                        ringColor: theme.accent.blue,
                      }}
                      onClick={() => {
                        const newMapping = `${category}.${name}`;
                        const newColor = color as string;
                        
                        // If clicking on the already mapped color, open its color wheel
                        if (colorPicker.mappedTo === newMapping) {
                          const hsl = hexToHsl(newColor);
                          setColorPicker({
                            isOpen: true,
                            originalColor: newColor,
                            currentColor: newColor,
                            hsl,
                            category: 'accent',
                            name: name,
                            position: { x: 0, y: 0 },
                            mappedTo: undefined,
                          });
                        } else {
                          // Otherwise, update the mapping
                          const hsl = hexToHsl(newColor);
                          setColorPicker({
                            ...colorPicker,
                            mappedTo: newMapping,
                            currentColor: newColor,
                            hsl,
                          });

                          onSemanticMapping(
                            colorPicker.category,
                            colorPicker.name,
                            newMapping,
                          );
                        }
                      }}
                    >
                      <div
                        className="w-4 h-4 rounded flex-shrink-0"
                        style={{ backgroundColor: color as string }}
                      />
                      <span className="text-xs font-mono truncate flex-1">{`${category}.${name}`}</span>
                      {colorPicker.mappedTo === `${category}.${name}` && (
                        <span className="text-xs opacity-60">→</span>
                      )}
                    </button>
                  ));
                }
                return null;
              })}
            </div>
            <div
              className="mt-4 pt-4 border-t"
              style={{ borderColor: theme.background.overlay }}
            >
              <p className="text-xs opacity-60">
                💡 To edit the actual color value, close this and click on <span className="font-mono">{colorPicker.mappedTo}</span> directly.
              </p>
            </div>
          </div>
        ) : (
          // For direct colors - show color wheel and controls
          <>
            {/* Show semantic usage for accent colors */}
            {colorPicker.category === 'accent' && getSemanticColorsUsingAccent().length > 0 && (
              <div
                className="mb-4 p-4 rounded border"
                style={{ borderColor: theme.background.overlay }}
              >
                <h4 className="font-semibold text-sm mb-2">Used by semantic colors:</h4>
                <div className="flex flex-wrap gap-2">
                  {getSemanticColorsUsingAccent().map((semantic) => (
                    <span
                      key={semantic}
                      className="px-3 py-1 rounded-lg text-xs font-medium"
                      style={{
                        backgroundColor: theme.background.overlay,
                        color: theme.foreground.primary,
                      }}
                    >
                      {semantic}
                    </span>
                  ))}
                </div>
              </div>
            )}
            
          <div className="flex gap-6">
          {/* Left side - Color wheel */}
          <div className="flex-shrink-0">
            <canvas
              ref={canvasRef}
              className="cursor-pointer"
              onMouseDown={handleCanvasMouseDown}
              onMouseMove={handleCanvasMouseMove}
              style={{ touchAction: 'none' }}
            />
          </div>

          {/* Right side - Controls */}
          <div className="flex-1 space-y-4">
            {/* Text preview with original and current colors */}
            <div className="flex gap-3">
              <div className="flex-1">
                <div className="text-xs opacity-75 mb-1">Original</div>
                <div
                  className="w-full h-16 rounded border flex items-center justify-center"
                  style={{
                    backgroundColor: theme.background.primary,
                    borderColor: theme.background.overlay,
                  }}
                >
                  <span
                    style={{
                      color: colorPicker.originalColor,
                      fontFamily: '"BerkeleyMono Nerd Font", "Berkeley Mono", monospace',
                      fontSize: '18px',
                      fontWeight: 500,
                    }}
                  >
                    example
                  </span>
                </div>
              </div>
              <div className="flex-1">
                <div className="text-xs opacity-75 mb-1">Current</div>
                <div
                  className="w-full h-16 rounded border flex items-center justify-center"
                  style={{
                    backgroundColor: theme.background.primary,
                    borderColor: theme.background.overlay,
                  }}
                >
                  <span
                    style={{
                      color: colorPicker.currentColor,
                      fontFamily: '"BerkeleyMono Nerd Font", "Berkeley Mono", monospace',
                      fontSize: '18px',
                      fontWeight: 500,
                    }}
                  >
                    example
                  </span>
                </div>
              </div>
            </div>

            {/* Color inputs */}
            <div className="space-y-3">
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="text-sm opacity-75">Original Color</label>
                  <button
                    onClick={() => {
                      const hsl = hexToHsl(colorPicker.originalColor);
                      setColorPicker({
                        ...colorPicker,
                        currentColor: colorPicker.originalColor,
                        hsl,
                      });
                      onColorChange(
                        colorPicker.category,
                        colorPicker.name,
                        colorPicker.originalColor,
                      );
                    }}
                    className="text-xs px-2 py-1 rounded hover:opacity-70 transition-opacity"
                    style={{
                      backgroundColor: theme.accent.blue,
                      color: "white",
                    }}
                  >
                    Reset
                  </button>
                </div>
                <input
                  type="text"
                  value={colorPicker.originalColor}
                  readOnly
                  className="w-full p-2 rounded border font-mono text-sm"
                  style={{
                    backgroundColor: theme.background.primary,
                    borderColor: theme.background.overlay,
                    color: theme.foreground.primary,
                  }}
                />
              </div>
              
              <div>
                <label className="text-sm opacity-75 block mb-1">
                  Current Color
                </label>
                <input
                  type="text"
                  value={colorPicker.currentColor}
                  onChange={(e) => {
                    const hex = e.target.value.toUpperCase();
                    // Update the display value immediately for better UX
                    setColorPicker({
                      ...colorPicker,
                      currentColor: hex,
                    });
                    
                    // Only update color if it's a valid hex
                    if (/^#[0-9A-F]{6}$/i.test(hex)) {
                      const hsl = hexToHsl(hex);
                      setColorPicker({
                        ...colorPicker,
                        currentColor: hex,
                        hsl,
                      });
                      onColorChange(
                        colorPicker.category,
                        colorPicker.name,
                        hex,
                      );
                    }
                  }}
                  onBlur={(e) => {
                    // On blur, ensure we have a valid hex value
                    const hex = e.target.value;
                    if (!/^#[0-9A-F]{6}$/i.test(hex)) {
                      // Revert to the last valid color
                      const hsl = hexToHsl(colorPicker.originalColor);
                      setColorPicker({
                        ...colorPicker,
                        currentColor: colorPicker.originalColor,
                        hsl,
                      });
                    }
                  }}
                  placeholder="#000000"
                  className="w-full p-2 rounded border font-mono text-sm"
                  style={{
                    backgroundColor: theme.background.primary,
                    borderColor: theme.background.overlay,
                    color: theme.foreground.primary,
                  }}
                />
              </div>

              {/* Saturation and Lightness sliders */}
              <div className="space-y-4">
                <ColorSlider
                  label="Saturation"
                  value={colorPicker.hsl.s}
                  onChange={(s) => {
                    const newHsl = { ...colorPicker.hsl, s };
                    const newColor = hslToHex(newHsl.h, newHsl.s, newHsl.l);
                    
                    setColorPicker({ ...colorPicker, hsl: newHsl, currentColor: newColor });
                    onColorChange(colorPicker.category, colorPicker.name, newColor);
                  }}
                  gradient={`linear-gradient(to right, 
                    hsl(${colorPicker.hsl.h}, 0%, ${colorPicker.hsl.l}%) 0%, 
                    hsl(${colorPicker.hsl.h}, 100%, ${colorPicker.hsl.l}%) 100%)`}
                  theme={theme}
                  isDarkMode={isDarkMode}
                />
                
                <ColorSlider
                  label="Lightness"
                  value={colorPicker.hsl.l}
                  onChange={(l) => {
                    const newHsl = { ...colorPicker.hsl, l };
                    const newColor = hslToHex(newHsl.h, newHsl.s, newHsl.l);
                    
                    setColorPicker({ ...colorPicker, hsl: newHsl, currentColor: newColor });
                    onColorChange(colorPicker.category, colorPicker.name, newColor);
                  }}
                  gradient={`linear-gradient(to right, 
                    hsl(${colorPicker.hsl.h}, ${colorPicker.hsl.s}%, 0%) 0%, 
                    hsl(${colorPicker.hsl.h}, ${colorPicker.hsl.s}%, 50%) 50%,
                    hsl(${colorPicker.hsl.h}, ${colorPicker.hsl.s}%, 100%) 100%)`}
                  theme={theme}
                  isDarkMode={isDarkMode}
                />
              </div>
            </div>
          </div>
        </div>
          </>
        )}
      </div>
    </div>
  );
}