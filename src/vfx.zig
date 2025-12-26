const std = @import("std");
const Random = std.Random;
const rl = @import("raylib");
const CONF = @import("config.zig").CONF;
const DB16 = @import("palette.zig").DB16;

const Particle = struct {
    x: f32,
    y: f32,
    size: f32,
    speed: f32,
};
pub const Vfx = struct {
    vfx: [32]Particle = undefined,
    prng: Random.DefaultPrng,
    pub fn init() !Vfx {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        const prng = Random.DefaultPrng.init(seed);
        const vfx: [32]Particle = undefined;
        var self = Vfx{
            .vfx = vfx,
            .prng = prng,
        };
        for (&self.vfx) |*p| {
            self.fillRandomRectangles(p);
        }
        return self;
    }
    pub fn draw(self: *Vfx, dt: f32) void {
        self.drawSnow(dt);
    }
    fn drawSnow(self: *Vfx, dt: f32) void {
        for (&self.vfx) |*p| {
            const alpha_color = rl.Color.alpha(rl.Color.white, CONF.VFX_SNOW_ALPHA * p.size / 4); // Semi-transparent white for snow effect
            const x: i32 = @intFromFloat(p.x - p.size * 0.5);
            const y: i32 = @intFromFloat(p.y - p.size * 0.5);
            const size: i32 = @intFromFloat(p.size);
            rl.drawRectangle(x, y, size, size, alpha_color);
            p.y += p.speed * dt;
            if (p.y > CONF.SCREEN_H) {
                self.fillRandomRectangles(p);
            }
        }
    }
    fn drawSpace(self: *Vfx, dt: f32) void {
        _ = self;
        _ = dt;
    }
    fn fillRandomRectangles(self: *Vfx, p: *Particle) void {
        const rand = self.prng.random();
        p.x = rand.float(f32) * CONF.SCREEN_W;
        p.y = -rand.float(f32) * (CONF.SCREEN_H);
        p.size = CONF.VFX_SNOW_MIN + rand.float(f32) * (CONF.VFX_SNOW_MAX - CONF.VFX_SNOW_MIN);
        p.speed = CONF.VFX_SNOW_SPEED_MIN + (p.size * 0.001) * CONF.VFX_SNOW_SPEED_MAX;
    }
};
