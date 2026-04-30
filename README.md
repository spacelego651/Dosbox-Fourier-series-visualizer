# Fourier Series Visualizer

A real-time x86 assembly program that visualizes periodic waveforms and their Fourier series approximations in DOS.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Assembly](https://img.shields.io/badge/assembly-x86-red.svg)
![Platform](https://img.shields.io/badge/platform-DOS-green.svg)

# About

This project was developed as part of my 10th grade Computer Architecture and Assembly Language class. It demonstrates how complex periodic functions can be decomposed into simpler sinusoidal components.

# Features

### Eight Waveform Types
1. **Square Wave** - Classic digital signal with sharp transitions
2. **Full-Wave Rectified Sine** - Absolute value of sine wave
3. **Non-symmetric Triangle Wave** - Asymmetric sawtooth-like wave
4. **Sawtooth Wave** - Linear ramp with sharp reset
5. **Pulse Train** - Periodic rectangular pulses (25% duty cycle)
6. **Step Function** - Multi-level discrete steps
7. **Piecewise Linear Function** - Connected linear segments
8. **Modulated Sine Wave** - AM modulation visualization

### Interactive Controls
- `SPACE` - Add 3 more harmonic terms to the approximation
- `LEFT ARROW` - Pan view left by π radians
- `RIGHT ARROW` - Pan view right by π radians
- `` ` `` (backtick) - Return to function selection menu
- `ESC` - Exit program

### Visual Features
- Color-coded original waveforms and Fourier approximations
- Labeled coordinate axes (X: -3π to 3π, Y: -1.5 to 1.5)
- Real-time rendering in 320×200 VGA graphics mode
- Progressive approximation improvement with more terms

# Build System

### Prerequisites
- **DOSBox** - DOS emulator ([download here](https://www.dosbox.com/))
- **TASM** (Turbo Assembler) - Borland's assembler
- **TLINK** (Turbo Linker) - Borland's linker

### Building the Project

1. **Prepare your directory structure:**
   ```
   your-project-folder/
   ├── fourier.asm
   ├── TASM.EXE
   └── TLINK.EXE
   ```

2. **Launch DOSBox and mount your directory:**
   ```
   mount c c:\path\to\your-project-folder
   c:
   ```

3. **Assemble the source file:**
   ```
   tasm fourier.asm
   ```
   This creates `fourier.obj`

4. **Link the object file:**
   ```
   tlink fourier.obj
   ```
   This creates `fourier.exe`

5. **Run the program:**
   ```
   fourier.exe
   ```

### Quick Build Script

You can also create a batch file (`build.bat`) for easier building:
```batch
@echo off
tasm fourier.asm
if errorlevel 1 goto error
tlink fourier.obj
if errorlevel 1 goto error
echo Build successful!
goto end
:error
echo Build failed!
:end
```

Then simply run:
```
build.bat
```

# Usage Guide

1. **Launch the program** - You'll see a welcome screen with instructions
2. **Select a waveform** - Enter a number from 1-8
3. **Observe the visualization:**
   - Green/colored line: Original waveform
   - Purple/white/yellow line: Fourier series approximation
4. **Add more terms** - Press `SPACE` to see the approximation improve (starts with 3 terms, max 21-27 depending on waveform)
5. **Explore the wave** - Use arrow keys to pan horizontally
6. **Try other waveforms** - Press `` ` `` to return to the menu

# Technical Implementation

### Architecture
- **Platform:** 16-bit x86 
- **Graphics Mode:** VGA Mode 13h (320×200, 256 colors)
- **Instruction Set:** Real mode x86 assembly

### Key Algorithms
- **Integer-based Trigonometry:** Uses a 91-entry sine lookup table (0-90°) with quadrant-based calculation
- **Fourier Coefficient Calculation:** Computes sine/cosine coefficients in real-time using scaled integer arithmetic
- **Coordinate Transformation:** Maps mathematical coordinates to screen pixels with proper scaling
- **No Floating Point:** All calculations use 16-bit signed integers with fixed-point scaling (values scaled by 100)

### Code Structure
```
fourier.asm
├── Data Section
│   ├── Sine lookup table (0-90° in 1° increments)
│   ├── Axis labels and menu strings
│   └── State variables (terms count, X offset)
├── Waveform Functions
│   ├── CALC_SQUARE, CALC_FOURIER (Square wave)
│   ├── CALC_RECTIFIED, CALC_RECTIFIED_FOURIER
│   ├── CALC_TRIANGLE, CALC_TRIANGLE_FOURIER
│   └── ... (6 more waveform pairs)
├── Graphics Functions
│   ├── PLOT_POINT (pixel drawing)
│   ├── PLOT_* (waveform rendering procedures)
│   └── CLEAR_SCREEN
└── Main Loop
    ├── Menu system
    ├── Graphics rendering
    └── Keyboard input handling
```

# Learning Outcomes

Through this project, I learned:
- DOS interrupt services (INT 10h for graphics, INT 21h for I/O)
- VGA graphics programming and pixel manipulation
- Integer mathematics and fixed-point arithmetic
- Optimization techniques for real-time rendering
- algorithm implementation in assembly

# Known Limitations

- Maximum 21-27 terms (memory and performance constraints)
- Integer arithmetic causes slight rounding errors
- No anti-aliasing (single-pixel line drawing)
- Fixed 320×200 resolution
- Requires DOS or DOSBox environment


# License

This project is available under the MIT License. Feel free to use it for educational purposes.

