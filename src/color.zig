const std = @import("std");
const Vec3F = @import("./vec3.zig").Vec3F;
const F = Vec3F.F;
const math = std.math;

pub fn write_color(writer: anytype, pixel_color: Vec3F, samples_per_pixel: usize) !void {
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();

    // Divide the color by the number of samples.
    const scale = 1.0 / @as(F, @floatFromInt(samples_per_pixel));
    r *= scale;
    g *= scale;
    b *= scale;
    r = @sqrt(r);
    g = @sqrt(g);
    b = @sqrt(b);

    // Write the translated [0,255] value of each color component.
    const lower = 0.0;
    const upper = 0.999;
    const ru = @as(u8, @intFromFloat(256 * math.clamp(r, lower, upper)));
    const gu = @as(u8, @intFromFloat(256 * math.clamp(g, lower, upper)));
    const bu = @as(u8, @intFromFloat(256 * math.clamp(b, lower, upper)));
    try std.fmt.format(writer, "{} {} {} \n", .{ ru, gu, bu });
}
