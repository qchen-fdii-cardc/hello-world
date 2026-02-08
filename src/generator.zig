const std = @import("std");
const sudoku = @import("sudoku.zig");
const solver_mod = @import("solver.zig");

/// Difficulty levels for Sudoku puzzles
pub const Difficulty = enum {
    easy,
    medium,
    hard,

    /// Get the number of cells to remove for this difficulty
    pub fn getCellsToRemove(self: Difficulty) usize {
        return switch (self) {
            .easy => 30,
            .medium => 45,
            .hard => 55,
        };
    }
};

/// Generator for Sudoku puzzles
pub const Generator = struct {
    allocator: std.mem.Allocator,
    random: std.Random,

    pub fn init(allocator: std.mem.Allocator, seed: u64) Generator {
        var prng = std.Random.DefaultPrng.init(seed);
        return Generator{
            .allocator = allocator,
            .random = prng.random(),
        };
    }

    /// Generate a random valid Sudoku puzzle
    pub fn generate(self: *Generator, difficulty: Difficulty) !sudoku.Grid {
        var grid = sudoku.Grid.init();
        
        // Fill the diagonal 3x3 boxes first (they don't interfere with each other)
        try self.fillDiagonalBoxes(&grid);
        
        // Fill remaining cells
        _ = try self.fillRemaining(&grid, 0, sudoku.BOX_SIZE);
        
        // Remove numbers based on difficulty
        try self.removeNumbers(&grid, difficulty.getCellsToRemove());
        
        return grid;
    }

    fn fillDiagonalBoxes(self: *Generator, grid: *sudoku.Grid) !void {
        var box: usize = 0;
        while (box < sudoku.SIZE) : (box += sudoku.BOX_SIZE) {
            try self.fillBox(grid, box, box);
        }
    }

    fn fillBox(self: *Generator, grid: *sudoku.Grid, row_start: usize, col_start: usize) !void {
        var numbers = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        
        // Shuffle the numbers
        for (0..numbers.len) |i| {
            const j = self.random.intRangeAtMost(usize, i, numbers.len - 1);
            const temp = numbers[i];
            numbers[i] = numbers[j];
            numbers[j] = temp;
        }
        
        // Fill the box
        var idx: usize = 0;
        for (0..sudoku.BOX_SIZE) |i| {
            for (0..sudoku.BOX_SIZE) |j| {
                grid.cells[row_start + i][col_start + j] = numbers[idx];
                idx += 1;
            }
        }
    }

    fn fillRemaining(self: *Generator, grid: *sudoku.Grid, row: usize, col: usize) !bool {
        var current_row = row;
        var current_col = col;
        
        // Move to next row if we've filled the current row
        if (current_col >= sudoku.SIZE) {
            current_row += 1;
            current_col = 0;
        }
        
        // If we've filled all rows, we're done
        if (current_row >= sudoku.SIZE) {
            return true;
        }
        
        // Skip cells in diagonal boxes (already filled)
        if (current_row < sudoku.BOX_SIZE and current_col < sudoku.BOX_SIZE) {
            return try self.fillRemaining(grid, current_row, current_col + sudoku.BOX_SIZE);
        } else if (current_row < sudoku.BOX_SIZE * 2 and current_col >= sudoku.BOX_SIZE and current_col < sudoku.BOX_SIZE * 2) {
            return try self.fillRemaining(grid, current_row, sudoku.BOX_SIZE * 2);
        } else if (current_row >= sudoku.BOX_SIZE * 2 and current_col >= sudoku.BOX_SIZE * 2) {
            return try self.fillRemaining(grid, current_row + 1, 0);
        }
        
        // If cell is already filled, move to next
        if (!grid.isEmpty(current_row, current_col)) {
            return try self.fillRemaining(grid, current_row, current_col + 1);
        }
        
        // Try numbers 1-9 in random order
        var numbers = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        for (0..numbers.len) |i| {
            const j = self.random.intRangeAtMost(usize, i, numbers.len - 1);
            const temp = numbers[i];
            numbers[i] = numbers[j];
            numbers[j] = temp;
        }
        
        for (numbers) |num| {
            if (grid.isValid(current_row, current_col, num)) {
                grid.cells[current_row][current_col] = num;
                if (try self.fillRemaining(grid, current_row, current_col + 1)) {
                    return true;
                }
                grid.cells[current_row][current_col] = 0;
            }
        }
        
        return false;
    }

    fn removeNumbers(self: *Generator, grid: *sudoku.Grid, count: usize) !void {
        var removed: usize = 0;
        const total_cells = sudoku.SIZE * sudoku.SIZE;
        
        while (removed < count and removed < total_cells - 17) { // At least 17 clues needed for unique solution
            const row = self.random.intRangeAtMost(usize, 0, sudoku.SIZE - 1);
            const col = self.random.intRangeAtMost(usize, 0, sudoku.SIZE - 1);
            
            if (!grid.isEmpty(row, col)) {
                grid.cells[row][col] = 0;
                removed += 1;
            }
        }
    }
};

test "generate easy puzzle" {
    const allocator = std.testing.allocator;
    var generator = Generator.init(allocator, 12345);
    
    const grid = try generator.generate(.easy);
    
    // Count empty cells
    var empty_count: usize = 0;
    for (0..sudoku.SIZE) |i| {
        for (0..sudoku.SIZE) |j| {
            if (grid.cells[i][j] == 0) {
                empty_count += 1;
            }
        }
    }
    
    // Should have approximately the right number of empty cells
    try std.testing.expect(empty_count > 0);
    try std.testing.expect(empty_count <= Difficulty.easy.getCellsToRemove());
}

test "generate puzzles with different difficulties" {
    const allocator = std.testing.allocator;
    
    var generator_easy = Generator.init(allocator, 11111);
    _ = try generator_easy.generate(.easy);
    
    var generator_medium = Generator.init(allocator, 22222);
    _ = try generator_medium.generate(.medium);
    
    var generator_hard = Generator.init(allocator, 33333);
    _ = try generator_hard.generate(.hard);
}
