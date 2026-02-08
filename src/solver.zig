const std = @import("std");
const sudoku = @import("sudoku.zig");

/// Step in the solving process
pub const SolveStep = struct {
    row: usize,
    col: usize,
    value: u8,
    action: Action,

    pub const Action = enum {
        place,
        backtrack,
    };
};

/// Solver for Sudoku puzzles with step tracking
pub const Solver = struct {
    allocator: std.mem.Allocator,
    steps: std.ArrayList(SolveStep),

    pub fn init(allocator: std.mem.Allocator) Solver {
        return Solver{
            .allocator = allocator,
            .steps = .empty,
        };
    }

    pub fn deinit(self: *Solver) void {
        self.steps.deinit(self.allocator);
    }

    /// Solve the Sudoku puzzle and track steps
    pub fn solve(self: *Solver, grid: *sudoku.Grid) !bool {
        self.steps.clearRetainingCapacity();
        return try self.solveRecursive(grid, 0, 0);
    }

    fn solveRecursive(self: *Solver, grid: *sudoku.Grid, row: usize, col: usize) !bool {
        // Find next empty cell
        var current_row = row;
        var current_col = col;
        var found = false;

        outer: while (current_row < sudoku.SIZE) : (current_row += 1) {
            current_col = if (current_row == row) col else 0;
            while (current_col < sudoku.SIZE) : (current_col += 1) {
                if (grid.isEmpty(current_row, current_col)) {
                    found = true;
                    break :outer;
                }
            }
        }

        // If no empty cell found, puzzle is solved
        if (!found) {
            return true;
        }

        // Try numbers 1-9
        for (1..10) |num_usize| {
            const num: u8 = @intCast(num_usize);
            if (grid.isValid(current_row, current_col, num)) {
                grid.set(current_row, current_col, num);
                
                // Record the step
                try self.steps.append(self.allocator, SolveStep{
                    .row = current_row,
                    .col = current_col,
                    .value = num,
                    .action = .place,
                });

                // Recursively try to solve
                if (try self.solveRecursive(grid, current_row, current_col + 1)) {
                    return true;
                }

                // Backtrack
                grid.set(current_row, current_col, 0);
                try self.steps.append(self.allocator, SolveStep{
                    .row = current_row,
                    .col = current_col,
                    .value = num,
                    .action = .backtrack,
                });
            }
        }

        return false;
    }

    /// Get the steps taken to solve the puzzle
    pub fn getSteps(self: *const Solver) []const SolveStep {
        return self.steps.items;
    }

    /// Print steps to a writer
    pub fn printSteps(self: *const Solver, writer: anytype) !void {
        for (self.steps.items, 0..) |step, i| {
            const action_str = if (step.action == .place) "Place" else "Backtrack";
            try writer.print("Step {d}: {s} {d} at ({d}, {d})\n", .{
                i + 1,
                action_str,
                step.value,
                step.row + 1,
                step.col + 1,
            });
        }
    }
};

test "solve simple puzzle" {
    const allocator = std.testing.allocator;
    var solver = Solver.init(allocator);
    defer solver.deinit();

    var grid = sudoku.Grid.init();
    
    // Create a simple puzzle
    grid.cells[0] = [_]u8{ 5, 3, 0, 0, 7, 0, 0, 0, 0 };
    grid.cells[1] = [_]u8{ 6, 0, 0, 1, 9, 5, 0, 0, 0 };
    grid.cells[2] = [_]u8{ 0, 9, 8, 0, 0, 0, 0, 6, 0 };
    grid.cells[3] = [_]u8{ 8, 0, 0, 0, 6, 0, 0, 0, 3 };
    grid.cells[4] = [_]u8{ 4, 0, 0, 8, 0, 3, 0, 0, 1 };
    grid.cells[5] = [_]u8{ 7, 0, 0, 0, 2, 0, 0, 0, 6 };
    grid.cells[6] = [_]u8{ 0, 6, 0, 0, 0, 0, 2, 8, 0 };
    grid.cells[7] = [_]u8{ 0, 0, 0, 4, 1, 9, 0, 0, 5 };
    grid.cells[8] = [_]u8{ 0, 0, 0, 0, 8, 0, 0, 7, 9 };

    const result = try solver.solve(&grid);
    try std.testing.expect(result);
    try std.testing.expect(solver.getSteps().len > 0);
}
