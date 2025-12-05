import React, { useRef, useState, useEffect } from 'react';

interface ColorSliderProps {
  label: string;
  value: number;
  min?: number;
  max?: number;
  onChange: (value: number) => void;
  gradient?: string;
  isDarkMode?: boolean;
  theme: {
    background: {
      overlay: string;
      primary: string;
      secondary: string;
      surface: string;
    };
    foreground: {
      primary: string;
      secondary: string;
      muted: string;
    };
    accent: {
      blue: string;
    };
  };
}

export function ColorSlider({ 
  label, 
  value, 
  min = 0, 
  max = 100, 
  onChange, 
  gradient,
  isDarkMode = false,
  theme 
}: ColorSliderProps) {
  const sliderRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const percentage = ((value - min) / (max - min)) * 100;

  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    updateValue(e);
  };

  const updateValue = (e: React.MouseEvent) => {
    if (!sliderRef.current) return;
    
    const rect = sliderRef.current.getBoundingClientRect();
    const x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
    const newValue = (x / rect.width) * (max - min) + min;
    onChange(Math.round(newValue));
  };

  // Set up global mouse events
  useEffect(() => {
    const handleGlobalMouseMove = (e: MouseEvent) => {
      if (isDragging && sliderRef.current) {
        const rect = sliderRef.current.getBoundingClientRect();
        const x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
        const newValue = (x / rect.width) * (max - min) + min;
        onChange(Math.round(newValue));
      }
    };

    const handleGlobalMouseUp = () => {
      setIsDragging(false);
    };

    if (isDragging) {
      document.addEventListener('mousemove', handleGlobalMouseMove);
      document.addEventListener('mouseup', handleGlobalMouseUp);
    }

    return () => {
      document.removeEventListener('mousemove', handleGlobalMouseMove);
      document.removeEventListener('mouseup', handleGlobalMouseUp);
    };
  }, [isDragging, min, max, onChange]);

  // Style configurations for light/dark mode matching Figma design
  const styles = {
    track: isDarkMode ? {
      backgroundColor: '#3a3a3a',
    } : {
      backgroundColor: '#e8e8e8',
    },
    fill: isDarkMode ? {
      backgroundColor: '#5a5a5a',
    } : {
      backgroundColor: '#b0b0b0',
    },
    thumb: isDarkMode ? {
      backgroundColor: '#707070',
      boxShadow: '0 1px 4px rgba(0, 0, 0, 0.3)',
    } : {
      backgroundColor: '#ffffff',
      boxShadow: '0 1px 4px rgba(0, 0, 0, 0.15)',
    },
    valueBox: isDarkMode ? {
      backgroundColor: 'rgba(255, 255, 255, 0.1)',
      color: theme.foreground.primary,
    } : {
      backgroundColor: '#f0f0f0',
      color: '#3a3a3a',
    }
  };

  return (
    <div className="space-y-2">
      {/* Label on top */}
      <label 
        className="text-sm font-medium block"
        style={{ color: theme.foreground.primary }}
      >
        {label}
      </label>
      
      <div className="flex items-center gap-3">
        {/* Slider - takes most of the width */}
        <div 
          ref={sliderRef}
          className="relative flex-1 h-8 cursor-pointer flex items-center"
          onMouseDown={handleMouseDown}
        >
          {/* Track container */}
          <div 
            className="absolute w-full h-4 rounded-lg overflow-hidden"
            style={styles.track}
          >
            {/* Filled portion */}
            <div 
              className="absolute h-full"
              style={{
                width: `${percentage}%`,
                ...styles.fill,
              }}
            />
          </div>
          
          {/* Thumb */}
          <div 
            className="absolute w-6 h-6 rounded-md"
            style={{
              left: `${percentage}%`,
              transform: `translateX(-50%)`,
              ...styles.thumb,
            }}
          />
        </div>

        {/* Value input box - smaller width */}
        <div 
          className="flex items-center gap-2 px-3 py-2 rounded-lg"
          style={{
            ...styles.valueBox,
            minWidth: '100px',
            maxWidth: '100px',
          }}
        >
          <span className="text-sm opacity-60">↔</span>
          <input
            type="text"
            value={(value / 100).toFixed(3)}
            onChange={(e) => {
              const val = parseFloat(e.target.value);
              if (!isNaN(val)) {
                onChange(Math.round(val * 100));
              }
            }}
            className="bg-transparent outline-none text-sm font-mono w-full text-center"
            style={{ color: styles.valueBox.color }}
          />
        </div>
      </div>
    </div>
  );
}