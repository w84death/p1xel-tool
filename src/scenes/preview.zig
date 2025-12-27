const std = @import("std");
const rl = @import("raylib");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const Palette = @import("../palette.zig").Palette;
const Ui = @import("../ui.zig").UI;
const PIVOTS = @import("../ui.zig").PIVOTS;
const State = @import("../state.zig").State;
const StateMachine = @import("../state.zig").StateMachine;
const Tiles = @import("../tiles.zig").Tiles;
const Edit = @import("edit.zig").EditScene;
const Popup = enum {
    none,
    info_not_implemented,
    info_save_ok,
    info_save_fail,
    confirm_delete,
};
pub const PreviewScene = struct {
    ui: Ui,
    sm: *StateMachine,
    palette: *Palette,
    tiles: *Tiles,
    selected: u8,
    locked: bool,
    popup: Popup,
    pub fn init(ui: Ui, sm: *StateMachine, pal: *Palette, tiles: *Tiles) PreviewScene {
        return PreviewScene{
            .ui = ui,
            .sm = sm,
            .tiles = tiles,
            .selected = 0,
            .palette = pal,
            .locked = false,
            .popup = Popup.none,
        };
    }
    pub fn draw(self: *PreviewScene, mouse: rl.Vector2) void {
        const nav: rl.Vector2 = rl.Vector2.init(self.ui.pivots[PIVOTS.TOP_LEFT].x, self.ui.pivots[PIVOTS.TOP_LEFT].y);
        var nav_step = nav.x;
        if (self.ui.button(nav_step, nav.y, 120, 32, "< Menu", CONF.COLOR_MENU_SECONDARY, mouse) and !self.locked) {
            self.sm.goTo(State.main_menu);
        }
        nav_step += 128 + 32;
    }
};
