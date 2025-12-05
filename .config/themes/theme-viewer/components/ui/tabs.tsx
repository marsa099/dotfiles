"use client"

import * as React from "react"
import * as TabsPrimitive from "@radix-ui/react-tabs"

const Tabs = TabsPrimitive.Root

const TabsList = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List> & {
    theme?: any
  }
>(({ className, theme, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={`inline-flex h-11 items-center justify-center rounded-xl p-1 ${className}`}
    style={{
      backgroundColor: theme?.background?.overlay || '#EBE4D6',
      border: `1px solid rgba(139, 125, 100, 0.15)`,
      boxShadow: 'inset 0 1px 2px 0 rgba(139, 125, 100, 0.08)',
      ...props.style
    }}
    {...props}
  />
))
TabsList.displayName = TabsPrimitive.List.displayName

const TabsTrigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger> & {
    theme?: any
  }
>(({ className, theme, children, ...props }, ref) => {
  const triggerRef = React.useRef<HTMLButtonElement>(null);
  const [isActive, setIsActive] = React.useState(false);
  
  React.useEffect(() => {
    const checkActive = () => {
      if (triggerRef.current) {
        setIsActive(triggerRef.current.getAttribute('data-state') === 'active');
      }
    };
    checkActive();
    const interval = setInterval(checkActive, 100);
    return () => clearInterval(interval);
  }, []);
  
  return (
    <TabsPrimitive.Trigger
      ref={(el) => {
        triggerRef.current = el;
        if (typeof ref === 'function') ref(el);
        else if (ref) ref.current = el;
      }}
      className={`inline-flex items-center justify-center whitespace-nowrap rounded-lg px-7 py-1.5 text-sm font-semibold transition-all focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50 ${className}`}
      style={{
        backgroundColor: isActive ? (theme?.background?.primary || '#fff') : 'transparent',
        color: isActive ? (theme?.foreground?.primary || '#000') : (theme?.foreground?.muted || '#888'),
        boxShadow: isActive ? '0 1px 3px 0 rgba(0, 0, 0, 0.08), 0 1px 2px 0 rgba(0, 0, 0, 0.04)' : 'none',
        ...(props.style || {})
      }}
      {...props}
    >
      {children}
    </TabsPrimitive.Trigger>
  );
})
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName

const TabsContent = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={`mt-6 ring-offset-white focus-visible:outline-none ${className}`}
    {...props}
  />
))
TabsContent.displayName = TabsPrimitive.Content.displayName

export { Tabs, TabsList, TabsTrigger, TabsContent }