const std = @import("std");
const write_color = @import("./color.zig").write_color;
const Vec3F = @import("./vec3.zig").Vec3F;
const F = Vec3F.F;
const Ray = @import("./ray.zig").Ray;
const Hittable = @import("./hittable.zig").Hittable;
const HittableList = @import("./hittable.zig").HittableList;
const Sphere = @import("./hittable.zig").Sphere;
const Camera = @import("./camera.zig").Camera;
const Material = @import("./material.zig").Material;
const Lambertian = @import("./material.zig").Lambertian;
const Metal = @import("./material.zig").Metal;
const Dielectric = @import("./material.zig").Dielectric;
// pub fn hit_sphere(center: Vec3F, radius: Vec3F.F, r: Ray) F {
//     const oc = r.orig.sub(center);
//     const a = r.dir.norm_sqr();
//     const half_b = oc.dot(r.dir);
//     const c = oc.norm_sqr() - radius * radius;
//     const discriminant = half_b * half_b - a * c;
//     if (discriminant < 0) {
//         return -1.0;
//     } else {
//         return (-half_b - @sqrt(discriminant)) / a;
//     }
// }

// pub fn ray_color(r: Ray, world: *HittableList) Vec3F {
//     if (world.hit(r, 0.0, std.math.floatMax(F))) |rec| {
//         return rec.normal.add(Vec3F.fill(1.0)).mul_s(0.5);
//     }

//     const unit_dir = r.dir.normalize();
//     const a = 0.5 * (unit_dir.y() + 1);
//     return Vec3F.fill(1 - a).add(Vec3F{ .data = .{ a * 0.5, a * 0.7, a } });
// }

pub fn cover_img() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var world = HittableList.init(alloc);
    defer world.deinit();

    var prng = std.rand.DefaultPrng.init(1);
    const random = prng.random();
    const ground_material_ptr = try alloc.create(Material);
    ground_material_ptr.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.5, 0.5, 0.5 } } } };
    const sphere_ground_ptr = try alloc.create(Hittable);
    sphere_ground_ptr.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, -1000, 0 } }, .material = ground_material_ptr, .radius = 1000 } };
    try world.append(sphere_ground_ptr);
    var ai: isize = -11;
    while (ai < 11) : (ai += 1) {
        const a = @as(f32, @floatFromInt(ai));
        var bi: isize = -11;
        while (bi < 11) : (bi += 1) {
            const b = @as(f32, @floatFromInt(bi));
            const choose_mat = random.float(F);
            const center = Vec3F{ .data = .{ a + 0.9 * random.float(F), 0.2, b + 0.9 * random.float(F) } };
            if ((center.sub(Vec3F{ .data = .{ 4, 0.2, 0 } })).norm() > 0.9) {
                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = Vec3F.random();
                    const sphere_material_ptr = try alloc.create(Material);
                    sphere_material_ptr.* = Material{ .lambertian = Lambertian{ .albedo = albedo } };
                    const sphere_ptr = try alloc.create(Hittable);
                    sphere_ptr.* = Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material_ptr, .radius = 0.2 } };
                    try world.append(sphere_ptr);
                } else if (choose_mat < 0.9) {
                    // metal
                    const albedo = Vec3F.random_between(0.5, 1);
                    const fuzz = random.float(F) / 2;
                    const sphere_material_ptr = try alloc.create(Material);

                    sphere_material_ptr.* = Material{ .metal = Metal{ .albedo = albedo, .fuzz = fuzz } };
                    const sphere_ptr = try alloc.create(Hittable);
                    sphere_ptr.* = Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material_ptr, .radius = 0.2 } };
                    try world.append(sphere_ptr);
                } else {
                    // glass
                    const sphere_material_ptr = try alloc.create(Material);
                    sphere_material_ptr.* = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
                    const sphere_ptr = try alloc.create(Hittable);
                    sphere_ptr.* = Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material_ptr, .radius = 0.2 } };
                    try world.append(sphere_ptr);
                }
            }
        }
    }

    const material1_ptr = try alloc.create(Material);
    material1_ptr.* = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    const sphere1_ptr = try alloc.create(Hittable);
    sphere1_ptr.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, 1, 0 } }, .material = material1_ptr, .radius = 1.0 } };
    try world.append(sphere1_ptr);
    const material2_ptr = try alloc.create(Material);
    material2_ptr.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.4, 0.2, 0.1 } } } };
    const sphere2_ptr = try alloc.create(Hittable);
    sphere2_ptr.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ -4, 1, 0 } }, .material = material2_ptr, .radius = 1.0 } };
    try world.append(sphere2_ptr);
    const material3_ptr = try alloc.create(Material);
    material3_ptr.* = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.7, 0.6, 0.5 } }, .fuzz = 0.0 } };
    const sphere3_ptr = try alloc.create(Hittable);
    sphere3_ptr.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 4, 1, 0 } }, .material = material3_ptr, .radius = 1.0 } };
    try world.append(sphere3_ptr);

    defer for (world.objects.items) |obj| {
        alloc.destroy(obj.sphere.material);
        alloc.destroy(obj);
    };

    const aspect_ratio: comptime_float = 16.0 / 9.0;
    const image_width: comptime_int = 600;
    const samples_per_pixel = 10;
    const max_depth = 50;

    const vfov = 20;
    const lookfrom = Vec3F{ .data = .{ 13, 2, 3 } };
    const lookat = Vec3F{ .data = .{ 0, 0, 0 } };
    const vup = Vec3F{ .data = .{ 0, 1, 0 } };
    const defocus_angle = 0.2;
    const focus_dist = 10.0;
    const cam = Camera.new(aspect_ratio, image_width, samples_per_pixel, max_depth, vfov, lookfrom, lookat, vup, focus_dist, defocus_angle);
    try cam.render(&world);
}

pub fn exercices() !void {
    // const foo = FooUnion{ .bar = Bar{} };
    // const foo2 = FooUnion{ .baz = Baz{} };
    // var temp = foo.boo();
    // temp = foo2.boo();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    // World
    const material_center = try alloc.create(Material);
    const material_ground = try alloc.create(Material);
    const material_left = try alloc.create(Material);
    const material_right = try alloc.create(Material);
    material_ground.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.8, 0.8, 0.0 } } } };
    // material_left.* = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.8, 0.8, 0.8 } }, .fuzz = 0.3} };
    // material_center.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.7, 0.7, 0.3 } } } };
    material_right.* = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.8, 0.6, 0.2 } }, .fuzz = 0.0 } };
    material_left.* = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    // material_center.* = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    // material_right.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.5, 0.5, 0.5 } } } };
    material_center.* = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.1, 0.2, 0.5 } } } };

    var world = HittableList.init(alloc);
    const sphere_ground = try alloc.create(Hittable);
    const sphere_center = try alloc.create(Hittable);
    const sphere_left = try alloc.create(Hittable);
    const sphere_right = try alloc.create(Hittable);
    sphere_ground.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, -100.5, -1 } }, .material = material_ground, .radius = 100 } };
    sphere_left.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ -1, 0, -1 } }, .material = material_left, .radius = 0.5 } };
    sphere_right.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 1, 0, -1 } }, .material = material_right, .radius = 0.5 } };
    sphere_center.* = Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, 0, -1 } }, .material = material_center, .radius = 0.5 } };
    try world.append(sphere_ground);
    try world.append(sphere_center);
    try world.append(sphere_left);
    try world.append(sphere_right);

    defer for (world.objects.items) |obj| {
        alloc.destroy(obj.sphere.material);
        alloc.destroy(obj);
    };

    defer world.deinit();
    // camera

    const aspect_ratio: comptime_float = 16.0 / 9.0;
    const image_width: comptime_int = 400;
    const samples_per_pixel = 50;
    const max_depth = 50;

    const vfov = 20;
    const lookfrom = Vec3F{ .data = .{ -2, 2, 1 } };
    const lookat = Vec3F{ .data = .{ 0, 0, -1 } };
    const vup = Vec3F{ .data = .{ 0, 1, 0 } };
    const defocus_angle = 10.0;
    const focus_dist = 3.4;

    const cam = Camera.new(aspect_ratio, image_width, samples_per_pixel, max_depth, vfov, lookfrom, lookat, vup, focus_dist, defocus_angle);
    // Render
    try cam.render(&world);
}
pub fn main() !void {
    try exercices();
    // try cover_img();
}
