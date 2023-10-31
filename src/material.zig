const std = @import("std");
const Vec3F = @import("vec3.zig").Vec3F;
const F = Vec3F.F;
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("hittable.zig").HitRecord;

pub const Material = union(enum) {
    const Self = @This();
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,
    pub fn scatter(self: Self, ray: Ray, hit_rec: HitRecord) ?struct { Ray, Vec3F } {
        switch (self) {
            inline else => |obj| return obj.scatter(ray, hit_rec),
        }
    }
};

pub const Lambertian = struct {
    const Self = @This();
    albedo: Vec3F,

    pub fn scatter(self: Self, ray: Ray, hit_rec: HitRecord) ?struct { Ray, Vec3F } {
        _ = ray;
        var scatter_direction = hit_rec.normal.add(Vec3F.random_unit_vector());
        if (scatter_direction.near_zero()) {
            scatter_direction = hit_rec.normal;
        }
        const scattered = Ray{ .orig = hit_rec.point, .dir = scatter_direction };
        const attenuation = self.albedo;
        return .{ scattered, attenuation };
    }
};

pub const Metal = struct {
    const Self = @This();
    albedo: Vec3F,
    fuzz: Vec3F.F,

    pub fn scatter(self: Self, ray: Ray, hit_rec: HitRecord) ?struct { Ray, Vec3F } {
        const fuzz = std.math.clamp(self.fuzz, 0, 1);
        const reflected = ray.dir.normalize().reflect(hit_rec.normal);
        const scattered = Ray{ .orig = hit_rec.point, .dir = reflected.add(Vec3F.random_unit_vector().mul_s(fuzz)) };
        const attenuation = self.albedo;
        if (scattered.dir.dot(hit_rec.normal) > 0.0) {
            return .{ scattered, attenuation };
        }
        return null;
    }
};

pub const Dielectric = struct {
    const Self = @This();
    var prng = std.rand.DefaultPrng.init(0);
    refraction_index: F,

    pub fn scatter(self: Self, ray: Ray, hit_rec: HitRecord) ?struct { Ray, Vec3F } {
        const attenuation = Vec3F.one();
        const refraction_ratio = if (hit_rec.front_face) 1.0 / self.refraction_index else self.refraction_index;

        const unit_dir = ray.dir.normalize();

        const cos_theta = @min(unit_dir.neg().dot(hit_rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
        const cannot_refract = refraction_ratio * sin_theta > 1.0;
        const refl = self.refelctance(cos_theta, refraction_ratio) > prng.random().float(f32);
        const dir = if (cannot_refract or refl) unit_dir.reflect(hit_rec.normal) else unit_dir.refract(hit_rec.normal, refraction_ratio);
        const scattered = Ray{ .orig = hit_rec.point, .dir = dir };
        return .{ scattered, attenuation };
    }

    fn refelctance(self: Self, cosine: F, ref_idx: F) F {
        _ = self;
        var r0 = (1 - ref_idx) / (1 + ref_idx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(F, (1 - cosine), 5);
    }
};
