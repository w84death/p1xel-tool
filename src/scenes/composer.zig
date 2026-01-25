const std = @import("std");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const Fui = @import("../fui.zig").Fui;
const PIVOTS = @import("../fui.zig").PIVOTS;
const State = @import("../state.zig").State;
const StateMachine = @import("../state.zig").StateMachine;
const Vec2 = @import("../math.zig").Vec2;
const Mouse = @import("../math.zig").Mouse;
const Audio = @import("../audio.zig").Audio;

const sample_rate = 44100.0;
const samples_per_frame = @as(usize, @intFromFloat(sample_rate / 30.0));

pub const ComposerScene = struct {
    fui: Fui,
    sm: *StateMachine,
    audio: Audio,
    pub fn init(fui: Fui, sm: *StateMachine) ComposerScene {
        return ComposerScene{
            .fui = fui,
            .sm = sm,
            .audio = Audio{ .playing = false, .freq = 0, .duration = 0, .phase = 0 },
        };
    }
    pub fn draw(self: *ComposerScene, mouse: Mouse) void {
        const px = self.fui.pivots[PIVOTS.TOP_LEFT].x;
        const py = self.fui.pivots[PIVOTS.TOP_LEFT].y;
        if (self.fui.button(px, py, 120, 32, "< Menu", CONF.COLOR_MENU_SECONDARY, mouse)) {
            self.sm.goTo(State.main_menu);
        }

        if (self.fui.button(px, py + 64, 200, 32, "Play Beep", CONF.COLOR_MENU_NORMAL, mouse)) {
            self.audio.play(800.0, 0.2);
        }

        if (self.fui.button(px, py + 64 + 40, 200, 32, "Play Beep", CONF.COLOR_MENU_NORMAL, mouse)) {
            self.audio.play(200.0, 0.2);
        }
    }
    pub fn update_audio(self: *ComposerScene) void {
        if (!self.audio.playing) return;
    }
};
