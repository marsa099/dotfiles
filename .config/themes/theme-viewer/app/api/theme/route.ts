import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';

export async function GET() {
  try {
    const colorsPath = path.join(process.cwd(), '..', 'colors.json');
    const fileContent = await fs.readFile(colorsPath, 'utf-8');
    const data = JSON.parse(fileContent);
    
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error reading colors.json:', error);
    return NextResponse.json(
      { error: 'Failed to read theme colors' },
      { status: 500 }
    );
  }
}