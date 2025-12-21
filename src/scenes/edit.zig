const std = @import("std");
const rl = @import("raylib");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const palette = @import("../palette.zig");
const Ui = @import("../ui.zig").UI;
const PIVOTS = @import("../ui.zig").PIVOTS;
const State = @import("../state.zig").State;
const StateMachine = @import("../state.zig").StateMachine;

const Canvas = struct {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
    data: [CONF.SPRITE_SIZE][CONF.SPRITE_SIZE]u8,
};

pub const Edit = struct {
    ui: Ui,
    sm: *StateMachine,
    canvas: Canvas,
    active_color: u8,
    current_palette_index: usize,
    current_palette: [4]u8,

    pub fn init(ui: Ui, sm: *StateMachine) Edit {
        const ix: i32 = @intFromFloat(ui.pivots[PIVOTS.TOP_LEFT].x + CONF.CANVAS_X);
        const iy: i32 = @intFromFloat(ui.pivots[PIVOTS.TOP_LEFT].y + CONF.CANVAS_Y);

        return Edit{
            .ui = ui,
            .sm = sm,
            .canvas = Canvas{
                .width = CONF.SPRITE_SIZE * CONF.GRID_SIZE,
                .height = CONF.SPRITE_SIZE * CONF.GRID_SIZE,
                .x = ix,
                .y = iy,
                .data = [_][CONF.SPRITE_SIZE]u8{[_]u8{0} ** CONF.SPRITE_SIZE} ** CONF.SPRITE_SIZE,
            },
            .active_color = 1,
            .current_palette_index = 0,
            .current_palette = [4]u8{ 0, 3, 7, 15 },
        };
    }
    pub fn handleKeyboard(self: *Edit) void {
        const key = rl.getKeyPressed();
        switch (key) {
            rl.KeyboardKey.one => self.active_color = 0,
            rl.KeyboardKey.two => self.active_color = 1,
            rl.KeyboardKey.three => self.active_color = 2,
            rl.KeyboardKey.four => self.active_color = 3,
            else => {},
        }
    }
    pub fn handleMouse(self: *Edit, mouse: rl.Vector2) void {
        const mx: i32 = @intFromFloat(mouse.x);
        const my: i32 = @intFromFloat(mouse.y);
        const mouse_cell_x: i32 = @divFloor(mx - self.canvas.x, CONF.GRID_SIZE);
        const mouse_cell_y: i32 = @divFloor(my - self.canvas.y, CONF.GRID_SIZE);

        if ((rl.isMouseButtonDown(rl.MouseButton.left) or rl.isMouseButtonDown(rl.MouseButton.right))) {
            var color: u8 = self.active_color;
            if (mouse_cell_x >= 0 and mouse_cell_x < CONF.SPRITE_SIZE and
                mouse_cell_y >= 0 and mouse_cell_y < CONF.SPRITE_SIZE)
            {
                if (rl.isMouseButtonDown(rl.MouseButton.right)) color = 0;
                self.canvas.data[@intCast(mouse_cell_y)][@intCast(mouse_cell_x)] = color;
            }
        }
    }
    pub fn draw(self: Edit, mouse: rl.Vector2) void {
        if (self.ui.button(self.ui.pivots[PIVOTS.TOP_LEFT].x, self.ui.pivots[PIVOTS.TOP_LEFT].y, 80, 32, "< Menu", DB16.BLUE, mouse)) {
            self.sm.goTo(State.main_menu);
        }

        rl.drawRectangleLines(
            self.canvas.x,
            self.canvas.y,
            self.canvas.width + CONF.CANVAS_FRAME_SIZE,
            self.canvas.height + CONF.CANVAS_FRAME_SIZE,
            DB16.STEEL_BLUE,
        );

        for (0..CONF.SPRITE_SIZE) |y| {
            for (0..CONF.SPRITE_SIZE) |x| {
                const idx = self.canvas.data[y][x];
                const db16_idx = self.current_palette[idx];
                const xx: i32 = @intCast(x * CONF.GRID_SIZE);
                const yy: i32 = @intCast(y * CONF.GRID_SIZE);
                var color: rl.Color = undefined;

                if (idx == 0 and self.current_palette[0] == 0) {
                    const checker = (x + y) % 2 == 0;
                    color = if (checker) rl.getColor(0x33333310) else rl.getColor(0xAAAAAA10);
                } else {
                    color = palette.getColorFromIndex(db16_idx);
                }
                rl.drawRectangle(
                    self.canvas.x + xx + @divFloor(CONF.CANVAS_FRAME_SIZE, 2),
                    self.canvas.y + yy + @divFloor(CONF.CANVAS_FRAME_SIZE, 2),
                    CONF.GRID_SIZE,
                    CONF.GRID_SIZE,
                    color,
                );
            }
        }
    }
};
