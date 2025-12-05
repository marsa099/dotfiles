"use client";

import { motion, AnimatePresence } from 'framer-motion';
import { useRef, useState, useEffect } from 'react';

interface ThemeToggleProps {
  currentMode: "dark" | "light";
  onToggle: () => void;
}

export function ThemeToggle({ currentMode, onToggle }: ThemeToggleProps) {
  const isDark = currentMode === "dark";
  const [isAnimating, setIsAnimating] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const handleToggle = () => {
    if (isAnimating) return;
    
    setIsAnimating(true);
    onToggle();
    
    // Prevent rapid toggling during animation
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    
    timeoutRef.current = setTimeout(() => {
      setIsAnimating(false);
    }, 700);
  };

  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);
  
  return (
    <motion.button
      onClick={handleToggle}
      className={`relative flex items-center gap-2 px-3 py-1.5 rounded-full backdrop-blur-sm transition-colors overflow-hidden ${
        isDark 
          ? "bg-white/10 border border-white/20 hover:bg-white/15" 
          : "bg-black/10 border border-black/20 hover:bg-black/15"
      }`}
      layout
      transition={{
        type: "spring",
        duration: 0.7,
        bounce: 0
      }}
      style={{ minWidth: "72px" }}
    >
      {/* Icon */}
      <motion.div 
        className={`w-4 h-4 relative ${isDark ? "text-white" : "text-black"}`}
        animate={{ rotate: isDark ? 0 : 180 }}
        transition={{
          type: "spring",
          duration: 0.7,
          bounce: 0
        }}
      >
        <svg 
          viewBox="0 0 20 20" 
          fill="none" 
          className="absolute inset-0"
        >
          {/* Sun rays (visible in light mode) */}
          <motion.g
            animate={{ 
              opacity: isDark ? 0 : 1,
              scale: isDark ? 0.8 : 1
            }}
            transition={{
              type: "spring",
              duration: 0.7,
              bounce: 0
            }}
          >
            <motion.path
              d="M10 2V4"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M10 16V18"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M4 10H2"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M18 10H16"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M5.64 5.64L4.22 4.22"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M15.78 15.78L14.36 14.36"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M5.64 14.36L4.22 15.78"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
            <motion.path
              d="M15.78 4.22L14.36 5.64"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </motion.g>
          
          {/* Sun/Moon circle */}
          <motion.circle
            cx="10"
            cy="10"
            r="4"
            fill="currentColor"
            animate={{
              scale: isDark ? 1 : 0.9
            }}
            transition={{
              type: "spring",
              duration: 0.7,
              bounce: 0
            }}
          />
          
          {/* Moon crescent mask (visible in dark mode) */}
          <motion.circle
            cx="12"
            cy="8"
            r="3"
            fill={isDark ? "#0F0F0F" : "#FDF6E3"}
            animate={{
              opacity: isDark ? 1 : 0,
              x: isDark ? -2 : 2
            }}
            transition={{
              type: "spring",
              duration: 0.7,
              bounce: 0
            }}
          />
        </svg>
      </motion.div>

      {/* Text */}
      <div className="relative w-8 h-4 flex items-center justify-center">
        <AnimatePresence mode="wait">
          <motion.span
            key={currentMode}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{
              type: "spring",
              duration: 0.3,
              bounce: 0
            }}
            className={`absolute text-xs font-medium ${isDark ? "text-white/90" : "text-black/90"}`}
          >
            {isDark ? "Dark" : "Light"}
          </motion.span>
        </AnimatePresence>
      </div>
    </motion.button>
  );
}