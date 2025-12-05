import { ColorTheme } from './types';

interface SaveChangesProps {
  hasChanges: boolean;
  isSaving: boolean;
  theme: ColorTheme;
  onSave: () => void;
}

export function SaveChanges({ hasChanges, isSaving, theme, onSave }: SaveChangesProps) {
  if (!hasChanges) return null;

  return (
    <div
      className="mt-12 p-6 rounded-2xl shadow-lg"
      style={{
        backgroundColor: theme.background.surface,
        border: `1px solid ${theme.background.overlay}`,
      }}
    >
      <div className="flex justify-between items-center">
        <div>
          <p className="font-semibold text-lg mb-1">
            You have unsaved changes
          </p>
          <p
            className="text-sm"
            style={{ color: theme.foreground.secondary }}
          >
            Changes are previewed live but won't be saved to your theme
            files until you submit.
          </p>
        </div>
        <button
          onClick={onSave}
          disabled={isSaving}
          className="px-8 py-3 rounded-xl font-semibold text-white hover:opacity-90 disabled:opacity-50 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all"
          style={{ backgroundColor: theme.accent.blue }}
        >
          {isSaving ? "Saving..." : "Save Theme Changes"}
        </button>
      </div>
    </div>
  );
}