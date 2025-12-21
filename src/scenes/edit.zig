const std = @import("std");
const rl = @import("raylib");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
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
    pub fn init(ui: Ui, sm: *StateMachine) Edit {
        const ix: i32 = @intFromFloat(ui.pivots[PIVOTS.TOP_LEFT].x + CONF.CANVAS_X);
        const iy: i32 = @intFromFloat(ui.pivots[PIVOTS.TOP_LEFT].y + CONF.CANVAS_Y);

        return Edit{ .ui = ui, .sm = sm, .canvas = Canvas{
            .width = CONF.SPRITE_SIZE * CONF.GRID_SIZE,
            .height = CONF.SPRITE_SIZE * CONF.GRID_SIZE,
            .x = ix,
            .y = iy,
            .data = [_][CONF.SPRITE_SIZE]u8{[_]u8{0} ** CONF.SPRITE_SIZE} ** CONF.SPRITE_SIZE,
        } };
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
                const checker = (x + y) % 2 == 0;
                const col = if (checker) rl.getColor(0x33333310) else rl.getColor(0xAAAAAA10);
                const xx: i32 = @intCast(x * CONF.GRID_SIZE);
                const yy: i32 = @intCast(y * CONF.GRID_SIZE);

                rl.drawRectangle(
                    self.canvas.x + xx + @divFloor(CONF.CANVAS_FRAME_SIZE, 2),
                    self.canvas.y + yy + @divFloor(CONF.CANVAS_FRAME_SIZE, 2),
                    CONF.GRID_SIZE,
                    CONF.GRID_SIZE,
                    col,
                );
            }
        }
    }
};
