# Sudoku Solver

A Sudoku puzzle generator and solver implemented in Zig with separate modules for generation and solving.

## Features

- **Sudoku Grid Module** (`sudoku.zig`): Core data structures and utilities for Sudoku grids
- **Generator Module** (`generator.zig`): Random Sudoku puzzle generation with three difficulty levels
  - Easy: ~30 cells removed
  - Medium: ~45 cells removed
  - Hard: ~55 cells removed
- **Solver Module** (`solver.zig`): Backtracking algorithm with step-by-step solution tracking
  - Records each placement and backtrack operation
  - Provides detailed solving steps

## Building

```bash
zig build
```

## Running

```bash
zig build run
```

This will:
1. Generate a random medium-difficulty Sudoku puzzle
2. Display the puzzle
3. Solve it using the backtracking algorithm
4. Display the solution
5. Show the first 10 steps of the solving process

## Testing

```bash
zig build test
```

## Project Structure

```
src/
├── main.zig         # Main executable with demo
├── root.zig         # Library root exporting all modules
├── sudoku.zig       # Core Sudoku grid data structure
├── generator.zig    # Puzzle generation module
└── solver.zig       # Puzzle solving module with step tracking
```

## Usage Example

```zig
const std = @import("std");
const sudoku = @import("sudoku.zig");
const generator = @import("generator.zig");
const solver = @import("solver.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Generate a puzzle
    var gen = generator.Generator.init(allocator, 12345);
    const puzzle = try gen.generate(.medium);

    // Solve it
    var sol = solver.Solver.init(allocator);
    defer sol.deinit();
    
    var grid = puzzle.clone();
    const solved = try sol.solve(&grid);
    
    if (solved) {
        const steps = sol.getSteps();
        std.debug.print("Solved in {d} steps!\n", .{steps.len});
    }
}
```

## Algorithm Details

### Puzzle Generation
1. Fill the three diagonal 3x3 boxes with random numbers (they don't interfere with each other)
2. Use backtracking to fill the remaining cells
3. Remove cells based on difficulty level

### Puzzle Solving
- Uses recursive backtracking algorithm
- Tries numbers 1-9 for each empty cell
- Validates placement against row, column, and 3x3 box constraints
- Records each step for visualization

## Requirements

- Zig 0.15.2 or compatible version

## License

This is a demonstration project for the hello-world repository.
