import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';

export async function POST(request: Request) {
  try {
    const { themeData, mode } = await request.json();
    
    if (!themeData || !mode) {
      return NextResponse.json(
        { error: 'Missing theme data or mode' },
        { status: 400 }
      );
    }

    const colorsPath = path.join(process.cwd(), '..', 'colors.json');
    
    // Read current colors.json
    const currentContent = await fs.readFile(colorsPath, 'utf-8');
    const currentData = JSON.parse(currentContent);
    
    // Update the specific mode's theme data
    currentData.themes[mode] = themeData;
    
    // Write back to colors.json
    await fs.writeFile(colorsPath, JSON.stringify(currentData, null, 2), 'utf-8');
    
    return NextResponse.json({ 
      success: true, 
      message: `Theme colors saved to colors.json! Run 'generate_themes' to regenerate the theme files.` 
    });
  } catch (error) {
    console.error('Error saving theme:', error);
    return NextResponse.json(
      { error: 'Failed to save theme' },
      { status: 500 }
    );
  }
}