const std = @import("std");
const assert = std.debug.assert;
const Vec3F = @import("./vec3.zig").Vec3F;
const F = @import("./types.zig").Float;
const Ray = @import("./ray.zig").Ray;
const Allocator = std.mem.Allocator;
const Material = @import("./material.zig").Material;
const tol = 0.01;

pub const HitRecord = struct {
    const Self = @This();
    t: Vec3F.F,
    point: Vec3F,
    normal: Vec3F,
    front_face: bool,
    material: *const Material,

    pub fn set_face_normal(self: *Self, r: Ray, outward_normal: Vec3F) void {
        assert(outward_normal.norm() - 1 < tol);
        self.front_face = r.dir.dot(outward_normal) < 0.0;
        self.normal = if (self.front_face) outward_normal else outward_normal.neg();
    }
};

pub const Sphere = struct {
    const Self = @This();

    // fields
    center: Vec3F,
    radius: F,
    material: *const Material,
    // methods
    pub fn hit(self: *const Self, r: Ray, ray_tmin: F, ray_tmax: F) ?HitRecord {
        const oc = r.orig.sub(self.center);
        const a = r.dir.norm_sqr();
        const half_b = oc.dot(r.dir);
        const c = oc.norm_sqr() - self.radius * self.radius;
        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0.0) {
            return null;
        }
        const discriminant_sqrt = @sqrt(discriminant);
        var root = (-half_b - discriminant_sqrt) / a;
        if ((root <= ray_tmin) or (ray_tmax <= root)) {
            root = (-half_b + discriminant_sqrt) / a;
            if ((root <= ray_tmin) or (ray_tmax <= root)) {
                return null;
            }
            return null;
        }
        const point = r.at(root);
        const outward_normal = point.sub(self.center).div_s(self.radius);
        var hit_rec = HitRecord{
            .t = root,
            .point = point,
            .front_face = false,
            .normal = outward_normal,
            .material = self.material,
        };
        hit_rec.set_face_normal(r, outward_normal);
        return hit_rec;
    }
};

pub const HittableList = struct {
    const Self = @This();
    // fields
    objects: std.ArrayList(*const Hittable),
    allocator: Allocator,
    // methods
    pub fn init(allocator: Allocator) Self {
        return Self{ .objects = std.ArrayList(*const Hittable).init(allocator), .allocator = allocator };
    }
    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }
    pub fn append(self: *Self, object: *const Hittable) !void {
        try self.objects.append(object);
    }
    pub fn hit(self: *const Self, r: Ray, t_min: F, t_max: F) ?HitRecord {
        var maybe_hit: ?HitRecord = null;
        var closest_so_far = t_max;
        for (self.objects.items) |object| {
            if (object.hit(r, t_min, closest_so_far)) |hit_rec| {
                closest_so_far = hit_rec.t;
                maybe_hit = hit_rec;
            }
        }
        return maybe_hit;
    }
};

pub const Hittable = union(enum) {
    const Self = @This();
    sphere: Sphere,
    hittable_list: HittableList,

    pub fn hit(self: *const Self, r: Ray, t_min: F, t_max: F) ?HitRecord {
        switch (self.*) {
            inline else => |obj| return obj.hit(r, t_min, t_max),
        }
    }
};
