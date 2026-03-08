const std = @import("std");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const Fui = @import("../fui.zig").Fui;
const PIVOTS = @import("../fui.zig").PIVOTS;
const State = @import("../state.zig").State;
const StateMachine = @import("../state.zig").StateMachine;
const Vec2 = @import("../math.zig").Vec2;
const Mouse = @import("../math.zig").Mouse;
const AudioMod = @import("../audio.zig");
const Audio = AudioMod.Audio;
const Note = AudioMod.Note;
const Tune = AudioMod.Tune;

const sample_rate = 44100.0;
const samples_per_frame = @as(usize, @intFromFloat(sample_rate / 30.0));

const NoteDef = struct {
    name: [:0]const u8,
    id: usize,
};

// Note duration for both preview and playback
const NOTE_DURATION = 0.125;

// Timeline constants
const NOTES_PER_ROW = 18;
const MAX_ROWS = 4;
const MAX_VISIBLE_NOTES = NOTES_PER_ROW * MAX_ROWS; // 128
const TIMELINE_CELL_SIZE = 64;
const TIMELINE_GAP = 4;

// Notes organized by category for horizontal layout
const LOW_NOTES = [_]NoteDef{
    .{ .name = "C-2", .id = AudioMod.NOTE_C2 },
    .{ .name = "D-2", .id = AudioMod.NOTE_D2 },
    .{ .name = "E-2", .id = AudioMod.NOTE_E2 },
    .{ .name = "F-2", .id = AudioMod.NOTE_F2 },
    .{ .name = "G-2", .id = AudioMod.NOTE_G2 },
    .{ .name = "A-2", .id = AudioMod.NOTE_A2 },
    .{ .name = "B-2", .id = AudioMod.NOTE_B2 },
    .{ .name = "C-3", .id = AudioMod.NOTE_C3 },
    .{ .name = "D-3", .id = AudioMod.NOTE_D3 },
    .{ .name = "E-3", .id = AudioMod.NOTE_E3 },
};

const MID_NOTES = [_]NoteDef{
    .{ .name = "F-3", .id = AudioMod.NOTE_F3 },
    .{ .name = "G-3", .id = AudioMod.NOTE_G3 },
    .{ .name = "A-3", .id = AudioMod.NOTE_A3 },
    .{ .name = "B-3", .id = AudioMod.NOTE_B3 },
    .{ .name = "C-4", .id = AudioMod.NOTE_C4 },
    .{ .name = "D-4", .id = AudioMod.NOTE_D4 },
    .{ .name = "E-4", .id = AudioMod.NOTE_E4 },
    .{ .name = "F-4", .id = AudioMod.NOTE_F4 },
    .{ .name = "G-4", .id = AudioMod.NOTE_G4 },
    .{ .name = "A-4", .id = AudioMod.NOTE_A4 },
};

const HIGH_NOTES = [_]NoteDef{
    .{ .name = "B-4", .id = AudioMod.NOTE_B4 },
    .{ .name = "C-5", .id = AudioMod.NOTE_C5 },
    .{ .name = "D-5", .id = AudioMod.NOTE_D5 },
    .{ .name = "E-5", .id = AudioMod.NOTE_E5 },
    .{ .name = "F-5", .id = AudioMod.NOTE_F5 },
    .{ .name = "G-5", .id = AudioMod.NOTE_G5 },
    .{ .name = "A-5", .id = AudioMod.NOTE_A5 },
    .{ .name = "B-5", .id = AudioMod.NOTE_B5 },
    .{ .name = "C-6", .id = AudioMod.NOTE_C6 },
    .{ .name = "D-6", .id = AudioMod.NOTE_D6 },
    .{ .name = "E-6", .id = AudioMod.NOTE_E6 },
    .{ .name = "F-6", .id = AudioMod.NOTE_F6 },
    .{ .name = "G-6", .id = AudioMod.NOTE_G6 },
    .{ .name = "A-6", .id = AudioMod.NOTE_A6 },
    .{ .name = "B-6", .id = AudioMod.NOTE_B6 },
};

const MAX_NOTES = MAX_VISIBLE_NOTES;

// Music theory helpers
const NoteLetter = enum {
    C,
    Cs,
    D,
    Ds,
    E,
    F,
    Fs,
    G,
    Gs,
    A,
    As,
    B,
};

fn getNoteLetter(id: usize) ?NoteLetter {
    // Note IDs are sequential: C2=1, Cs2=2, D2=3, etc.
    // Each octave has 12 notes (1-12 for octave 2, 13-24 for octave 3, etc.)
    if (id == AudioMod.NOTE_REST) return null;
    const octave_offset = (id - 1) % 12;
    return switch (octave_offset) {
        0 => .C,
        1 => .Cs,
        2 => .D,
        3 => .Ds,
        4 => .E,
        5 => .F,
        6 => .Fs,
        7 => .G,
        8 => .Gs,
        9 => .A,
        10 => .As,
        11 => .B,
        else => unreachable,
    };
}

fn noteLettersMatch(id1: usize, id2: usize) bool {
    const l1 = getNoteLetter(id1);
    const l2 = getNoteLetter(id2);
    if (l1 == null or l2 == null) return false;
    return l1.? == l2.?;
}

fn getNoteName(id: usize) [:0]const u8 {
    for (LOW_NOTES) |n| {
        if (n.id == id) return n.name;
    }
    for (MID_NOTES) |n| {
        if (n.id == id) return n.name;
    }
    for (HIGH_NOTES) |n| {
        if (n.id == id) return n.name;
    }
    return "???";
}

const ComposerMode = enum {
    Insert,
    Preview,
};

pub const ComposerScene = struct {
    fui: Fui,
    sm: *StateMachine,
    audio: Audio,
    melody: [MAX_NOTES]Note,
    melody_len: usize,
    mode: ComposerMode,
    preview_buf: [1]Note,
    prev_mouse_pressed: bool = false,
    selected_letter: ?NoteLetter = null,

    pub fn init(fui: Fui, sm: *StateMachine) ComposerScene {
        return ComposerScene{
            .fui = fui,
            .sm = sm,
            .audio = Audio.init(),
            .melody = undefined,
            .melody_len = 0,
            .mode = .Insert,
            .preview_buf = undefined,
            .prev_mouse_pressed = false,
            .selected_letter = null,
        };
    }

    pub fn draw(self: *ComposerScene, mouse: Mouse) void {
        var click_mouse = mouse;
        click_mouse.pressed = mouse.pressed and !self.prev_mouse_pressed;
        self.prev_mouse_pressed = mouse.pressed;
        const px = self.fui.pivots[PIVOTS.TOP_LEFT].x;
        const py = self.fui.pivots[PIVOTS.TOP_LEFT].y;

        // Navigation
        if (self.fui.button(px, py, 120, 32, "< Menu", CONF.COLOR_MENU_SECONDARY, click_mouse)) {
            self.audio.stop_tune();
            self.sm.goTo(State.main_menu);
        }

        // Playback Controls
        if (self.fui.button(px + 130, py, 100, 32, "Play", CONF.COLOR_MENU_NORMAL, click_mouse)) {
            if (self.melody_len > 0) {
                self.audio.play_tune(self.melody[0..self.melody_len]);
            }
        }
        if (self.fui.button(px + 240, py, 100, 32, "Stop", CONF.COLOR_MENU_NORMAL, click_mouse)) {
            self.audio.stop_tune();
        }
        if (self.fui.button(px + 350, py, 100, 32, "Clear", CONF.COLOR_MENU_DANGER, click_mouse)) {
            self.audio.stop_tune();
            self.melody_len = 0;
        }

        const mode_str = switch (self.mode) {
            .Insert => "Insert",
            .Preview => "Preview",
        };
        if (self.fui.button(px + 460, py, 100, 32, mode_str, CONF.COLOR_MENU_HIGHLIGHT, click_mouse)) {
            self.mode = if (self.mode == .Insert) .Preview else .Insert;
        }

        // Timeline / Tracker - Grid at top
        const timeline_y = py + 48;
        self.fui.draw_text("Tracker:", px, timeline_y, CONF.FONT_DEFAULT_SIZE, CONF.COLOR_MENU_TEXT);

        const grid_start_y = timeline_y + 28;
        const cell_total = TIMELINE_CELL_SIZE + TIMELINE_GAP;

        // Draw grid: 32 columns x 4 rows
        var row: usize = 0;
        while (row < MAX_ROWS) : (row += 1) {
            var col: usize = 0;
            while (col < NOTES_PER_ROW) : (col += 1) {
                const idx = row * NOTES_PER_ROW + col;
                const cell_x = px + @as(i32, @intCast(col * cell_total));
                const cell_y = grid_start_y + @as(i32, @intCast(row * cell_total));

                var color: u32 = CONF.COLOR_MENU_SECONDARY;
                var label: [:0]const u8 = "";

                if (idx < self.melody_len) {
                    // Has note
                    const note = self.melody[idx];
                    if (self.audio.playing and self.audio.current_note == idx) {
                        color = CONF.COLOR_MENU_HIGHLIGHT;
                    } else {
                        color = CONF.COLOR_MENU_NORMAL;
                    }
                    label = if (note.id == AudioMod.NOTE_REST) "..." else getNoteName(note.id);
                } else {
                    // Empty slot
                    color = CONF.COLOR_MENU_SECONDARY;
                    label = "";
                }

                if (self.fui.button(cell_x, cell_y, TIMELINE_CELL_SIZE, TIMELINE_CELL_SIZE, label, color, click_mouse)) {
                    if (idx < self.melody_len) {
                        // Remove note
                        self.audio.stop_tune();
                        var k = idx;
                        while (k < self.melody_len - 1) : (k += 1) {
                            self.melody[k] = self.melody[k + 1];
                        }
                        self.melody_len -= 1;
                    }
                }
            }
        }

        // Note Palette at bottom
        const palette_y = grid_start_y + @as(i32, @intCast(MAX_ROWS * cell_total)) + 24;

        // Draw horizontal note rows
        self.drawNoteRow("Low:", px, palette_y, &LOW_NOTES, click_mouse);
        self.drawNoteRow("Mid:", px, palette_y + 36, &MID_NOTES, click_mouse);
        self.drawNoteRow("Hi:", px, palette_y + 72, &HIGH_NOTES, click_mouse);

        // Rest button row
        const rest_y = palette_y + 108;
        const rest_color: u32 = if (self.selected_letter == null) CONF.COLOR_MENU_HIGHLIGHT else CONF.COLOR_MENU_SECONDARY;
        if (self.fui.button(px, rest_y, 60, 28, "REST", rest_color, click_mouse)) {
            self.audio.stop_tune();
            self.preview_buf[0] = .{ .id = AudioMod.NOTE_REST, .dur = NOTE_DURATION };
            self.audio.play_tune(&self.preview_buf);

            // Reset the selected letter
            self.selected_letter = null;

            if (self.mode == .Insert and self.melody_len < MAX_NOTES) {
                self.melody[self.melody_len] = .{ .id = AudioMod.NOTE_REST, .dur = NOTE_DURATION };
                self.melody_len += 1;
            }
        }
    }

    fn drawNoteRow(self: *ComposerScene, label: [:0]const u8, x: i32, y: i32, notes: []const NoteDef, click_mouse: Mouse) void {
        self.fui.draw_text(label, x, y + 6, CONF.FONT_DEFAULT_SIZE, CONF.COLOR_MENU_TEXT);
        var btn_x = x + 80 + 8;
        for (notes) |note_def| {
            // Determine button color based on music theory matching
            var btn_color: u32 = CONF.COLOR_MENU_NORMAL;
            if (self.selected_letter) |sel| {
                const note_letter = getNoteLetter(note_def.id);
                if (note_letter) |nl| {
                    if (nl == sel) {
                        // Same note letter across octaves - highlight!
                        btn_color = CONF.COLOR_MENU_HIGHLIGHT;
                    }
                }
            }

            if (self.fui.button(btn_x, y, 80, 28, note_def.name, btn_color, click_mouse)) {
                self.audio.stop_tune();
                self.preview_buf[0] = .{ .id = note_def.id, .dur = NOTE_DURATION };
                self.audio.play_tune(&self.preview_buf);

                // Set this note's letter as the selected one
                self.selected_letter = getNoteLetter(note_def.id);

                if (self.mode == .Insert and self.melody_len < MAX_NOTES) {
                    self.melody[self.melody_len] = .{ .id = note_def.id, .dur = NOTE_DURATION };
                    self.melody_len += 1;
                }
            }
            btn_x += 88;
        }
    }

    pub fn update_audio(self: *ComposerScene, dt: f32) void {
        self.audio.update_audio(dt);
    }

    pub fn deinit(self: *ComposerScene) void {
        self.audio.deinit();
    }
};
