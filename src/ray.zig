const std = @import("std");
const Vec3F = @import("vec3.zig").Vec3F;

pub const Ray = struct {
    const Self = @This();
    orig: Vec3F,
    dir: Vec3F,

    pub fn at(self: Self, t: Vec3F.F) Vec3F {
        return self.orig.add(self.dir.mul_s(t));
    }
};
