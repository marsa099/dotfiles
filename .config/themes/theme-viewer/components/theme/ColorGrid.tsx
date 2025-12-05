import { ColorTheme } from './types';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../ui/tabs';

interface ColorGridProps {
  theme: ColorTheme;
  rawThemeData?: any;
  currentMode?: 'dark' | 'light';
  onColorClick: (category: string, name: string, color: string) => void;
  selectedAccent: string | null;
  getSemanticColorsUsingAccent: (accentName: string) => string[];
}

export function ColorGrid({
  theme,
  rawThemeData,
  currentMode = 'dark',
  onColorClick,
  selectedAccent,
  getSemanticColorsUsingAccent,
}: ColorGridProps) {
  const renderColorSection = (category: string, colors: any) => {
    return (
      <div
        key={category}
        className="rounded-2xl p-6 shadow-lg hover:shadow-xl transition-all"
        style={{
          backgroundColor: theme.background.primary,
          border: `1px solid ${theme.background.overlay}`,
        }}
      >
        <h3 className="font-semibold text-lg mb-4 capitalize flex items-center gap-2">
          {category.replace("_", " ")}
          {category === "accent" && (
            <span
              className="text-xs font-normal px-2 py-1 rounded-full"
              style={{
                backgroundColor: theme.background.overlay,
                color: theme.foreground.secondary,
              }}
            >
              Click to see usage
            </span>
          )}
        </h3>
        <div className="space-y-3">
          {Object.entries(colors).map(([name, color]) => {
            const semanticUsage =
              category === "accent"
                ? getSemanticColorsUsingAccent(name)
                : [];
            const isSelected =
              category === "accent" && selectedAccent === name;

            return (
              <div key={name} className="flex flex-col gap-2">
                <div className="flex items-center gap-3 group">
                  <div
                    className={`w-10 h-10 rounded-lg shadow-md cursor-pointer hover:scale-110 transition-all ${
                      isSelected ? "ring-2 ring-offset-2" : ""
                    }`}
                    style={{
                      backgroundColor: color,
                      ringColor: theme.accent.blue,
                      ringOffsetColor: theme.background.primary,
                      boxShadow: isSelected
                        ? `0 0 0 2px ${theme.background.primary}, 0 0 0 4px ${theme.accent.blue}`
                        : `0 4px 6px -1px ${theme.background.overlay}40`,
                    }}
                    onClick={() =>
                      onColorClick(category, name, color)
                    }
                  />
                  <div className="flex-1">
                    <div className="flex items-baseline justify-between">
                      <span className="font-medium capitalize text-sm">
                        {name.replace("_", " ")}
                      </span>
                      <span className="font-mono text-xs opacity-60 group-hover:opacity-100 transition-opacity">
                        {(() => {
                          // Check if this is a semantic color with a mapping
                          if (category === 'semantic' && rawThemeData) {
                            const rawValue = rawThemeData.themes[currentMode].semantic[name];
                            if (rawValue && !rawValue.startsWith('#')) {
                              // Show the mapping instead of hex (e.g., "accent.red" -> "red")
                              return rawValue.replace('accent.', '').replace('foreground.', 'fg.').replace('background.', 'bg.');
                            }
                          }
                          // Check if this is a terminal color with a mapping
                          if (category === 'terminal' && rawThemeData) {
                            const rawValue = rawThemeData.themes[currentMode].terminal[name];
                            if (rawValue && !rawValue.startsWith('#')) {
                              // Show the mapping instead of hex
                              return rawValue.replace('accent.', '').replace('foreground.', 'fg.').replace('background.', 'bg.');
                            }
                          }
                          return color;
                        })()}
                      </span>
                    </div>
                  </div>
                </div>
                {isSelected && semanticUsage.length > 0 && (
                  <div
                    className="p-3 rounded-lg ml-13 mt-2"
                    style={{
                      backgroundColor: theme.background.surface,
                      border: `1px solid ${theme.background.overlay}`,
                    }}
                  >
                    <div
                      className="font-medium text-xs mb-2"
                      style={{ color: theme.foreground.secondary }}
                    >
                      Used by:
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {semanticUsage.map((semantic) => (
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
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <div>
      <h2 className="text-3xl font-bold mb-8 tracking-tight">
        All Theme Colors
      </h2>
      
      <Tabs defaultValue="base" className="w-full">
        <div className="flex justify-center mb-8">
          <TabsList theme={theme}>
            <TabsTrigger value="base" theme={theme}>
              Base
            </TabsTrigger>
            <TabsTrigger value="fgbg" theme={theme}>
              Fg/Bg
            </TabsTrigger>
            <TabsTrigger value="terminal" theme={theme}>
              Terminal
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="base">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {theme.semantic && renderColorSection('semantic', theme.semantic)}
            {theme.accent && renderColorSection('accent', theme.accent)}
          </div>
        </TabsContent>

        <TabsContent value="fgbg">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {theme.foreground && renderColorSection('foreground', theme.foreground)}
            {theme.background && renderColorSection('background', theme.background)}
          </div>
        </TabsContent>

        <TabsContent value="terminal">
          <div className="grid grid-cols-1 gap-6">
            {theme.terminal && renderColorSection('terminal', theme.terminal)}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}