const std = @import("std");
const hello_world = @import("hello_world");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== Sudoku Solver Demo ===\n\n", .{});

    // Generate a random puzzle
    const timestamp = @as(u64, @intCast(std.time.milliTimestamp()));
    var generator = hello_world.generator.Generator.init(allocator, timestamp);
    
    std.debug.print("Generating a Medium difficulty puzzle...\n\n", .{});
    const puzzle = try generator.generate(.medium);
    
    std.debug.print("Generated Puzzle:\n", .{});
    try printGrid(&puzzle);
    
    // Solve the puzzle
    std.debug.print("\nSolving the puzzle...\n", .{});
    var grid_copy = puzzle.clone();
    var solver = hello_world.solver.Solver.init(allocator);
    defer solver.deinit();
    
    const solved = try solver.solve(&grid_copy);
    
    if (solved) {
        std.debug.print("\nSolved Puzzle:\n", .{});
        try printGrid(&grid_copy);
        
        const steps = solver.getSteps();
        std.debug.print("\nSolution found in {d} steps!\n", .{steps.len});
        
        // Show first 10 steps
        std.debug.print("\nFirst 10 steps:\n", .{});
        const max_steps = @min(10, steps.len);
        for (steps[0..max_steps], 0..) |step, i| {
            const action_str = if (step.action == .place) "Place" else "Backtrack";
            std.debug.print("  Step {d}: {s} {d} at row {d}, col {d}\n", .{
                i + 1,
                action_str,
                step.value,
                step.row + 1,
                step.col + 1,
            });
        }
    } else {
        std.debug.print("Failed to solve the puzzle.\n", .{});
    }

    std.debug.print("\n=== Demo Complete ===\n", .{});
}

fn printGrid(grid: *const hello_world.sudoku.Grid) !void {
    std.debug.print("+-------+-------+-------+\n", .{});
    for (0..hello_world.sudoku.SIZE) |row| {
        if (row == 3 or row == 6) {
            std.debug.print("+-------+-------+-------+\n", .{});
        }
        std.debug.print("| ", .{});
        for (0..hello_world.sudoku.SIZE) |col| {
            if (col == 3 or col == 6) {
                std.debug.print("| ", .{});
            }
            if (grid.cells[row][col] == 0) {
                std.debug.print(". ", .{});
            } else {
                std.debug.print("{d} ", .{grid.cells[row][col]});
            }
        }
        std.debug.print("|\n", .{});
    }
    std.debug.print("+-------+-------+-------+\n", .{});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
