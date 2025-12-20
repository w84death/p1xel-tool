const std = @import("std");
const rl = @import("raylib");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const Ui = @import("../ui.zig").UI;
const PIVOTS = @import("../ui.zig").PIVOTS;
const State = @import("../state_machine.zig").State;
const StateMachine = @import("../state_machine.zig").StateMachine;

pub const Intro = struct {
    ui: Ui,
    sm: *StateMachine,
    pub fn init(ui: Ui, sm: *StateMachine) Intro {
        return Intro{
            .ui = ui,
            .sm = sm,
        };
    }
    pub fn draw(self: Intro, mouse: rl.Vector2) void {
        const cx: i32 = @intFromFloat(self.ui.pivots[PIVOTS.CENTER].x);
        const cy: i32 = @intFromFloat(self.ui.pivots[PIVOTS.CENTER].y);
        const fx: f32 = self.ui.pivots[PIVOTS.CENTER].x;
        const fy: f32 = self.ui.pivots[PIVOTS.CENTER].y;
        const menu_y: f32 = fy + 70;
        const welcome = "Welcome to the indexed pixelart editor!";
        rl.drawText(CONF.THE_NAME, cx - @divFloor(rl.measureText(CONF.THE_NAME, CONF.DEFAULT_FONT_SIZE), 2), cy, CONF.DEFAULT_FONT_SIZE, self.ui.primary_color);
        rl.drawText(welcome, cx - @divFloor(rl.measureText(welcome, CONF.DEFAULT_FONT_SIZE), 2), cy + 22, CONF.DEFAULT_FONT_SIZE, self.ui.primary_color);

        if (self.ui.button(fx - 100, menu_y, 200, 32, "New Tileset", DB16.BLUE, mouse)) {
            self.sm.goTo(State.tileset);
        }

        if (self.ui.button(fx - 100, menu_y + 38, 200, 32, "Open Tileset", DB16.BLUE, mouse)) {
            self.sm.goTo(State.editor);
        }
    }
};
