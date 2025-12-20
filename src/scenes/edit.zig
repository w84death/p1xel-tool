const std = @import("std");
const rl = @import("raylib");
const CONF = @import("../config.zig").CONF;
const DB16 = @import("../palette.zig").DB16;
const UI = @import("../ui.zig").UI;
const PIVOTS = @import("../ui.zig").PIVOTS;
const State = @import("../state_machine.zig").State;
const StateMachine = @import("../state_machine.zig").StateMachine;

pub const Edit = struct {
    ui: UI,
    
};