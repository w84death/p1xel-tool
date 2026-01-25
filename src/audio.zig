const std = @import("std");

pub const Audio = struct {
    playing: bool,
    freq: f32,
    duration: f32,
    phase: f32,
    pub fn play(self: *Audio, f: f32, d: f32) void {
        self.freq = f;
        self.duration = d;
        self.phase = 0;
        self.playing = true;
    }
};
