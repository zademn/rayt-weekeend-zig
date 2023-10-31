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
    var ground_material = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.5, 0.5, 0.5 } } } };
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, -1000, 0 } }, .material = ground_material, .radius = 1000 } });
    var ai: isize = -11;
    while (ai < 11) : (ai += 1) {
        const a = @as(f32, @floatFromInt(ai));
        var bi: isize = -11;
        while (bi < 11) : (bi += 1) {
            const b = @as(f32, @floatFromInt(bi));
            const choose_mat = random.float(F);
            const center = Vec3F{ .data = .{ a + 0.9 * random.float(F), 0.2, b + 0.9 * random.float(F) } };
            if ((center.sub(Vec3F{ .data = .{ 4, 0.2, 0 } })).norm() > 0.9) {
                if (choose_mat < 1) {
                    // diffuse
                    const albedo = Vec3F.random();
                    // const sphere_material_ptr = try alloc.create(Material);
                    const sphere_material = Material{ .lambertian = Lambertian{ .albedo = albedo } };
                    try world.append(Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material, .radius = 0.2 } });
                } else if (choose_mat < 0.6) {
                    // metal
                    const albedo = Vec3F.random_between(0.5, 1);
                    const fuzz = random.float(F) / 2;
                    const sphere_material = Material{ .metal = Metal{ .albedo = albedo, .fuzz = fuzz } };
                    try world.append(Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material, .radius = 0.2 } });
                } else {
                    // glass
                    const sphere_material = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
                    try world.append(Hittable{ .sphere = Sphere{ .center = center, .material = sphere_material, .radius = 0.2 } });
                }
            }
        }
    }

    const material1 = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, 1, 0 } }, .material = material1, .radius = 1.0 } });
    const material2 = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.4, 0.2, 0.1 } } } };
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ -4, 1, 0 } }, .material = material2, .radius = 1.0 } });
    const material3 = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.7, 0.6, 0.5 } }, .fuzz = 0.0 } };
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 4, 1, 0 } }, .material = material3, .radius = 1.0 } });

    const aspect_ratio: comptime_float = 16.0 / 9.0;
    const image_width: comptime_int = 400;
    const samples_per_pixel = 10;
    const max_depth = 5;

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
    const material_ground = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.8, 0.8, 0.0 } } } };
    // const material_left = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.8, 0.8, 0.8 } }, .fuzz = 0.3} };
    // const material_center = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.7, 0.7, 0.3 } } } };
    const material_right = Material{ .metal = Metal{ .albedo = Vec3F{ .data = .{ 0.8, 0.6, 0.2 } }, .fuzz = 0.0 } };
    const material_left = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    // const material_center = Material{ .dielectric = Dielectric{ .refraction_index = 1.5 } };
    // const material_right = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.5, 0.5, 0.5 } } } };
    const material_center = Material{ .lambertian = Lambertian{ .albedo = Vec3F{ .data = .{ 0.1, 0.2, 0.5 } } } };

    var world = HittableList.init(alloc);
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, -100.5, -1 } }, .material = &material_ground, .radius = 100 } });
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 0, 0, -1 } }, .material = &material_center, .radius = 0.5 } });
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ -1, 0, -1 } }, .material = &material_left, .radius = 0.5 } });
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ -1, 0, -1 } }, .material = &material_left, .radius = -0.4 } });
    try world.append(Hittable{ .sphere = Sphere{ .center = Vec3F{ .data = .{ 1, 0, -1 } }, .material = &material_right, .radius = 0.5 } });
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
    // try exercices();
    try cover_img();
}
