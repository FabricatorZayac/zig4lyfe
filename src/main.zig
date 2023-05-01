const std = @import("std");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const DISPLAY_WIDTH = 600;
const DISPLAY_HEIGHT = 600;

const GRID_WIDTH = 50;
const GRID_HEIGHT = 50;

const CELL_SIZE = DISPLAY_HEIGHT / GRID_HEIGHT;

const CELL_COLOR = 0xfb4934;
const CELL_OUTLINE = 0x928374;

const FRAMERATE = 10;

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("life", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, DISPLAY_WIDTH, DISPLAY_HEIGHT, c.SDL_WINDOW_OPENGL) orelse {
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var grid: [GRID_HEIGHT * GRID_WIDTH]bool = undefined;
    for (grid) |*cell| cell.* = false;

    grid[3 + 1 * GRID_WIDTH] = true;
    grid[3 + 2 * GRID_WIDTH] = true;
    grid[3 + 3 * GRID_WIDTH] = true;
    grid[2 + 3 * GRID_WIDTH] = true;
    grid[1 + 2 * GRID_WIDTH] = true;

    var quit = false;
    var last_ticks = c.SDL_GetTicks();
    var running = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => quit = true,
                c.SDL_KEYDOWN => running = !running,
                c.SDL_MOUSEBUTTONDOWN => {
                    var mouse_x: i32 = undefined;
                    var mouse_y: i32 = undefined;
                    _ = c.SDL_GetMouseState(&mouse_x, &mouse_y);
                    mouse_x = @divFloor(mouse_x, CELL_SIZE);
                    mouse_y = @divFloor(mouse_y, CELL_SIZE);
                    std.debug.print("x: {}, y: {}\n", .{ mouse_x, mouse_y });
                    grid[@intCast(usize, mouse_x + mouse_y * GRID_WIDTH)] = !grid[@intCast(usize, mouse_x + mouse_y * GRID_WIDTH)];
                },
                else => {},
            }
        }

        if (c.SDL_GetTicks() - last_ticks < 1000 / FRAMERATE) {
            continue;
        }
        last_ticks = c.SDL_GetTicks();

        setColor(renderer, 0x1d2021);
        _ = c.SDL_RenderClear(renderer);

        // renderDemo(renderer);
        renderGrid(renderer, &grid);
        if (running) lifeTick(&grid);

        c.SDL_RenderPresent(renderer);
    }
}

fn lifeTick(grid: *[GRID_WIDTH * GRID_HEIGHT]bool) void {
    var new_grid: [GRID_WIDTH * GRID_HEIGHT]bool = undefined;

    outer: for (grid) |cell, i| {
        if (@divFloor(i, GRID_WIDTH) == 0 or @mod(i, GRID_WIDTH) == 0) {
            new_grid[i] = false;
            continue;
        }

        const pos = @intCast(i32, i);
        var neighbors: i32 = 0;
        // TODO: bounds checking
        var x: i32 = -1;
        while (x <= 1) : (x += 1) {
            var y: i32 = -GRID_WIDTH;
            while (y <= GRID_WIDTH) : (y += GRID_WIDTH) {
                // std.debug.print("{}\n", .{pos + x + y});
                if (pos + x + y >= GRID_WIDTH * GRID_HEIGHT) break :outer;
                if (x + y == 0) {
                    continue;
                } else if (grid[@intCast(usize, pos + x + y)]) neighbors += 1;
            }
        }
        if (neighbors < 2 or neighbors > 3) {
            new_grid[i] = false;
        } else if (neighbors == 3) {
            new_grid[i] = true;
        } else {
            new_grid[i] = cell;
        }
    }
    grid.* = new_grid;
}

fn renderGrid(renderer: *c.SDL_Renderer, grid: []bool) void {
    for (grid) |cell, i| {
        var pos = @intCast(i32, i);
        if (cell) renderCell(renderer, &makeCell(@mod(pos, GRID_WIDTH), @divFloor(pos, GRID_WIDTH)));
    }
}

fn renderDemo(renderer: *c.SDL_Renderer) void {
    var i: i32 = 0;
    while (i < GRID_WIDTH) : (i += 1) {
        renderCell(renderer, &makeCell(i, i));
    }
}

fn makeCell(x: i32, y: i32) c.SDL_Rect {
    return c.SDL_Rect{
        .x = x * CELL_SIZE,
        .y = y * CELL_SIZE,
        .w = CELL_SIZE,
        .h = CELL_SIZE,
    };
}

fn renderCell(renderer: *c.SDL_Renderer, rect: *const c.SDL_Rect) void {
    setColor(renderer, CELL_COLOR);
    _ = c.SDL_RenderFillRect(renderer, rect);
    setColor(renderer, CELL_OUTLINE);
    _ = c.SDL_RenderDrawRect(renderer, rect);
}

fn setColor(renderer: *c.SDL_Renderer, color: u24) void {
    _ = c.SDL_SetRenderDrawColor(renderer, @truncate(u8, color >> 16) & 0xFF, @truncate(u8, color >> 8) & 0xFF, @truncate(u8, color >> 0) & 0xFF, 0xFF);
}
