const std = @import("std");
const expect = std.testing.expect;
const F = @import("types.zig").Float;

pub fn Vec3(comptime T: type) type {
    return struct {
        const Self = @This();
        const V3 = @Vector(3, T);
        pub const F = T;
        var prng = std.rand.DefaultPrng.init(0);

        data: @Vector(3, T),
        pub fn x(self: Self) T {
            return self.data[0];
        }
        pub fn y(self: Self) T {
            return self.data[1];
        }
        pub fn z(self: Self) T {
            return self.data[2];
        }
        pub fn zero() Self {
            return Self{ .data = .{ 0, 0, 0 } };
        }
        pub fn one() Self {
            return Self{ .data = .{ 1, 1, 1 } };
        }
        pub fn fill(value: T) Self {
            return Self{ .data = @splat(value) };
        }
        pub fn eql(self: Self, other: Self) bool {
            return std.meta.eql(self.data, other.data);
        }
        pub fn neg(self: Self) Self {
            return Self{ .data = -self.data };
        }
        pub fn add(self: Self, other: Self) Self {
            return Self{ .data = self.data + other.data };
        }
        pub fn sub(self: Self, other: Self) Self {
            return Self{ .data = self.data - other.data };
        }
        pub fn mul(self: Self, other: Self) Self {
            return Self{ .data = self.data * other.data };
        }
        pub fn div(self: Self, other: Self) Self {
            return Self{ .data = self.data / other.data };
        }
        pub fn add_s(self: Self, other: T) Self {
            return Self{ .data = self.data + @as(V3, @splat(other)) };
        }
        pub fn sub_s(self: Self, other: T) Self {
            return Self{ .data = self.data - @as(V3, @splat(other)) };
        }
        pub fn mul_s(self: Self, other: T) Self {
            return Self{ .data = self.data * @as(V3, @splat(other)) };
        }
        pub fn div_s(self: Self, other: T) Self {
            return Self{ .data = self.data / @as(V3, @splat(other)) };
        }
        pub fn sqrt(self: Self) Self {
            return Self{ .data = @sqrt(self.data) };
        }
        pub fn sqr(self: Self) Self {
            return Self{ .data = self.data * self.data };
        }
        pub fn dot(self: Self, other: Self) T {
            return @reduce(.Add, self.data * other.data);
        }
        pub fn norm(self: Self) T {
            return @sqrt(self.dot(self));
        }
        pub fn norm_sqr(self: Self) T {
            return self.dot(self);
        }
        pub fn normalize(self: Self) Self {
            return self.div(Self{ .data = @splat(self.norm()) });
        }
        pub fn cross(self: Self, other: Self) Self {
            return Self{
                .data = .{
                    self.y() * other.z() - self.z() * other.y(),
                    self.z() * other.x() - self.x() * other.z(),
                    self.x() * other.y() - self.y() * other.x(),
                },
            };
        }
        pub fn random() Self {
            const rand = prng.random();
            return Self{ .data = .{ rand.float(T), rand.float(T), rand.float(T) } };
        }
        pub fn random_between(min: T, max: T) Self {
            const rand = prng.random();
            const v = Self{ .data = .{ rand.float(T), rand.float(T), rand.float(T) } };
            return v.mul_s(max - min).add_s(min);
        }
        pub fn random_in_sphere() Self {
            while (true) {
                const v = Self.random_between(-1, 1);
                if (v.norm_sqr() < 1) {
                    return v;
                }
            }
        }
        pub fn random_unit_vector() Self {
            return Self.random_in_sphere().normalize();
        }
        pub fn random_on_hemisphere(normal: Self) Self {
            const v = Self.random_unit_vector();
            if (v.dot(normal) > 0) {
                return v;
            }
            return v.neg();
        }
        pub fn random_in_unit_disk() Self {
            while (true) {
                var p = Self.random_between(-1, 1);
                p.data[2] = 0; // z = 0
                if (p.norm_sqr() < 1) {
                    return p;
                }
            }
        }
        pub fn near_zero(self: Self) bool {
            const s = 1e-8;
            return self.x() < s and self.y() < s and self.z() < s;
        }
        pub fn reflect(self: Self, normal: Self) Self {
            return self.sub(normal.mul_s(2 * self.dot(normal)));
        }
        pub fn refract(self: Self, normal: Self, etai_over_etat: T) Self {
            const cos_theta = @min((self.neg()).dot(normal), 1.0);
            const r_out_perp = (self.add(normal.mul_s(cos_theta))).mul_s(etai_over_etat);
            const r_out_parallel = normal.mul_s(-@sqrt(@abs(1.0 - r_out_perp.norm_sqr())));
            return r_out_parallel.add(r_out_perp);
        }
    };
}

pub const Vec3f32 = Vec3(f32);
pub const Vec3f64 = Vec3(f64);
pub const Vec3F = Vec3(F);

test "Vec3" {
    try expect(std.meta.eql(Vec3F.zero().data, .{ 0, 0, 0 }));
    try expect(std.meta.eql(Vec3F.one().data, .{ 1, 1, 1 }));

    const v1 = Vec3F{ .data = [3]f32{ 2, 2, 2 } };
    const v2 = Vec3F{ .data = [3]f32{ 6, 6, 6 } };
    try expect(std.meta.eql(v1.add(v2).data, .{ 8, 8, 8 }));
    try expect(std.meta.eql(v1.sub(v2).data, .{ -4, -4, -4 }));
    try expect(std.meta.eql(v1.mul(v2).data, .{ 12, 12, 12 }));
    try expect(std.meta.eql(v2.div(v1).data, .{ 3, 3, 3 }));
    try expect(std.meta.eql(v1.add_s(2.0).data, .{ 4, 4, 4 }));
    try expect(std.meta.eql(v1.sub_s(2.0).data, .{ 0, 0, 0 }));
    try expect(std.meta.eql(v1.mul_s(2.0).data, .{ 4, 4, 4 }));
    try expect(std.meta.eql(v1.div_s(2.0).data, .{ 1, 1, 1 }));
    try expect(v1.dot(v2) == 36.0);
    try expect(std.meta.eql(v1.sqr().data, .{ 4, 4, 4 }));
    try expect(std.meta.eql(v1.sqrt().data, .{ 1.41421356237, 1.41421356237, 1.41421356237 }));
    try expect(v1.norm() == 3.46410161514);
    try expect(v1.norm_sqr() == 12.0);
    try expect(std.meta.eql(v1.normalize().data, .{ 0.57735026919, 0.57735026919, 0.57735026919 }));
    try expect(std.meta.eql(v1.cross(v2).data, .{ 0, 0, 0 }));

    const v_r = Vec3F.random();
    const v_r2 = Vec3F.random_between(12, 24);
    _ = v_r2;
    _ = v_r;
}
