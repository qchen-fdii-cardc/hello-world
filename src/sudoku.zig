const std = @import("std");

/// Sudoku grid size (9x9)
pub const SIZE: usize = 9;
pub const BOX_SIZE: usize = 3;

/// Represents a Sudoku grid
pub const Grid = struct {
    cells: [SIZE][SIZE]u8,

    pub fn init() Grid {
        var grid = Grid{ .cells = undefined };
        for (0..SIZE) |i| {
            for (0..SIZE) |j| {
                grid.cells[i][j] = 0;
            }
        }
        return grid;
    }

    pub fn isValid(self: *const Grid, row: usize, col: usize, num: u8) bool {
        // Check row
        for (0..SIZE) |i| {
            if (self.cells[row][i] == num) {
                return false;
            }
        }

        // Check column
        for (0..SIZE) |i| {
            if (self.cells[i][col] == num) {
                return false;
            }
        }

        // Check 3x3 box
        const box_row = (row / BOX_SIZE) * BOX_SIZE;
        const box_col = (col / BOX_SIZE) * BOX_SIZE;
        for (0..BOX_SIZE) |i| {
            for (0..BOX_SIZE) |j| {
                if (self.cells[box_row + i][box_col + j] == num) {
                    return false;
                }
            }
        }

        return true;
    }

    pub fn print(self: *const Grid, writer: anytype) !void {
        try writer.writeAll("┌───────┬───────┬───────┐\n");
        for (0..SIZE) |row| {
            if (row == 3 or row == 6) {
                try writer.writeAll("├───────┼───────┼───────┤\n");
            }
            try writer.writeAll("│ ");
            for (0..SIZE) |col| {
                if (col == 3 or col == 6) {
                    try writer.writeAll("│ ");
                }
                if (self.cells[row][col] == 0) {
                    try writer.writeAll(". ");
                } else {
                    try writer.print("{d} ", .{self.cells[row][col]});
                }
            }
            try writer.writeAll("│\n");
        }
        try writer.writeAll("└───────┴───────┴───────┘\n");
    }

    pub fn isEmpty(self: *const Grid, row: usize, col: usize) bool {
        return self.cells[row][col] == 0;
    }

    pub fn set(self: *Grid, row: usize, col: usize, value: u8) void {
        self.cells[row][col] = value;
    }

    pub fn get(self: *const Grid, row: usize, col: usize) u8 {
        return self.cells[row][col];
    }

    pub fn clone(self: *const Grid) Grid {
        var new_grid = Grid{ .cells = undefined };
        for (0..SIZE) |i| {
            for (0..SIZE) |j| {
                new_grid.cells[i][j] = self.cells[i][j];
            }
        }
        return new_grid;
    }
};

test "grid initialization" {
    const grid = Grid.init();
    for (0..SIZE) |i| {
        for (0..SIZE) |j| {
            try std.testing.expect(grid.cells[i][j] == 0);
        }
    }
}

test "grid isValid" {
    var grid = Grid.init();
    grid.cells[0][0] = 5;
    
    // Same row
    try std.testing.expect(!grid.isValid(0, 1, 5));
    
    // Same column
    try std.testing.expect(!grid.isValid(1, 0, 5));
    
    // Same box
    try std.testing.expect(!grid.isValid(1, 1, 5));
    
    // Different position
    try std.testing.expect(grid.isValid(4, 4, 5));
}
