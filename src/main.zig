const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const Ui = @import("ui.zig").UI;
const PIVOTS = @import("ui.zig").PIVOTS;
const DB16 = @import("palette.zig").DB16;
const CONF = @import("config.zig").CONF;
const StateMachine = @import("state_machine.zig").StateMachine;
const State = @import("state_machine.zig").State;
const Intro = @import("scenes/intro.zig").Intro;

pub fn main() !void {
    const ui = Ui.init(CONF.THE_NAME, DB16.NAVY_BLUE, DB16.YELLOW);
    var sm = StateMachine.init(State.intro);
    const intro = Intro.init(ui, &sm);

    ui.createWindow();
    defer ui.closeWindow();

    rl.setTargetFPS(60);

    // var canvas_main = [_][SPRITE_SIZE]u8{[_]u8{0} ** SPRITE_SIZE} ** SPRITE_SIZE;

    var shouldClose = false;
    while (!rl.windowShouldClose() and !shouldClose) {
        const mouse = rl.getMousePosition();
        sm.update();
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(ui.bg_color);
        if (sm.is(State.intro)) intro.draw(mouse);

        if (ui.button(ui.pivots[PIVOTS.TOP_RIGHT].x - 100, ui.pivots[PIVOTS.TOP_RIGHT].y, 100, 32, "Quit", DB16.RED, mouse)) {
            shouldClose = true;
        }
    }
}
