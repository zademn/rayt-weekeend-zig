const std = @import("std");
const HittableList = @import("hittable.zig").HittableList;
const Ray = @import("ray.zig").Ray;
const Vec3F = @import("./vec3.zig").Vec3F;
const F = Vec3F.F;
const write_color = @import("./color.zig").write_color;
const Progress = std.Progress;

pub const Camera = struct {
    const Self = @This();
    var prng = std.rand.DefaultPrng.init(0);
    const random_state = prng.random();
    aspect_ratio: F,
    image_width: usize,
    samples_per_pixel: usize,
    max_depth: usize,
    image_height: usize,
    center: Vec3F,
    focal_length: F,
    vfov: F,
    lookfrom: Vec3F = Vec3F{ .data = .{ 0, 0, -1 } },
    lookat: Vec3F = Vec3F{ .data = .{ 0, 0, 0 } },
    vup: Vec3F = Vec3F{ .data = .{ 0, 1, 0 } },

    defocus_angle: f32 = 0,
    focus_dist: f32 = 10,

    // Private
    pixel_delta_u: Vec3F,
    pixel_delta_v: Vec3F,
    pixel00_loc: Vec3F,
    u: Vec3F,
    v: Vec3F,
    w: Vec3F,
    defocus_disk_u: Vec3F,
    defocus_disk_v: Vec3F,

    pub fn new(aspect_ratio: f32, image_width: usize, samples_per_pixel: usize, max_depth: usize, vfov: f32, lookfrom: Vec3F, lookat: Vec3F, vup: Vec3F, focus_dist: f32, defocus_angle: f32) Self {
        const iw_F = @as(F, @floatFromInt(image_width));
        const image_height = @as(usize, @intFromFloat(iw_F / aspect_ratio));
        const ih_F = @as(F, @floatFromInt(image_height));
        const center = lookfrom;
        const focal_length = lookfrom.sub(lookat).norm();

        const theta = std.math.degreesToRadians(F, vfov);
        const h = @tan(theta / 2.0);

        const w = lookfrom.sub(lookat).normalize();
        const u = vup.cross(w).normalize();
        const v = w.cross(u).normalize();
        //viewport
        // const viewport_height: f32 = 2.0 * h * focal_length;
        const viewport_height = 2 * h * focus_dist;
        const viewport_width: F = viewport_height * iw_F / ih_F;
        const viewport_u = u.mul_s(viewport_width);
        const viewport_v = v.neg().mul_s(viewport_height);
        // const viewport_upper_left = center.sub(w.mul_s(focal_length)).sub(viewport_u.div_s(2)).sub(viewport_v.div_s(2));
        const viewport_upper_left = center.sub(w.mul_s(focus_dist)).sub(viewport_u.div_s(2)).sub(viewport_v.div_s(2));
        const pixel_delta_u = viewport_u.div_s(iw_F);
        const pixel_delta_v = viewport_v.div_s(ih_F);
        const pixel00_loc = viewport_upper_left.add((pixel_delta_u.add(pixel_delta_v)).mul_s(0.5));

        const defocus_radius = focus_dist * @tan(std.math.degreesToRadians(f32, defocus_angle / 2));
        const defocus_disk_u = u.mul_s(defocus_radius);
        const defocus_disk_v = v.mul_s(defocus_radius);
        return Self{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .max_depth = max_depth,
            .center = center,
            .focal_length = focal_length,
            .vfov = vfov,
            .lookfrom = lookfrom,
            .lookat = lookat,
            .vup = vup,
            .defocus_angle = defocus_angle,
            .focus_dist = focus_dist,
            //private
            .u = u,
            .v = v,
            .w = w,
            .defocus_disk_u = defocus_disk_u,
            .defocus_disk_v = defocus_disk_v,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .pixel00_loc = pixel00_loc,
            .samples_per_pixel = samples_per_pixel,
        };
    }
    pub fn render(self: Self, world: *HittableList) !void {
        var progress = Progress{};
        const root_node = progress.start("Rows", self.image_height);
        defer root_node.end();

        const stdout = std.io.getStdOut();
        const writer = stdout.writer();
        try std.fmt.format(writer, "P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            root_node.activate();
            for (0..self.image_width) |i| {
                var color = Vec3F.zero();
                for (0..self.samples_per_pixel) |_| {
                    const r = self.get_ray(i, j);
                    color = color.add(ray_color(r, self.max_depth, world));
                }
                try write_color(writer, color, self.samples_per_pixel);
            }
            root_node.completeOne();
        }
    }

    fn get_ray(self: Self, i: usize, j: usize) Ray {
        const pixel_center = self.pixel00_loc.add(self.pixel_delta_u.mul_s(@as(F, @floatFromInt(i)))).add(self.pixel_delta_v.mul_s(@as(F, @floatFromInt(j))));
        const pixel_sample = pixel_center.add(self.pixel_sample_sqr());

        const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocus_disk_sample();
        const ray_direction = pixel_sample.sub(ray_origin);
        return Ray{ .orig = ray_origin, .dir = ray_direction };
    }

    fn defocus_disk_sample(self: Self) Vec3F {
        const p = Vec3F.random_in_unit_disk();
        return self.center.add(self.defocus_disk_u.mul_s(p.x())).add(self.defocus_disk_v.mul_s(p.y()));
    }

    fn pixel_sample_sqr(self: Self) Vec3F {
        const px = random_state.float(F) - 0.5;
        const py = random_state.float(F) - 0.5;
        return self.pixel_delta_u.mul_s(px).add(self.pixel_delta_v.mul_s(py));
    }
    fn ray_color(r: Ray, depth: usize, world: *HittableList) Vec3F {
        if (depth <= 0) {
            return Vec3F.zero();
        }
        if (world.hit(r, 0.001, std.math.floatMax(F) - 1)) |rec| {
            // const dir = Vec3F.random_on_hemisphere(rec.normal);
            // const scattered, const attenuation = if (rec.material.scatter(r, rec)) |tup| tup else {
            //     return Vec3F.zero();
            // };
            // return attenuation.mul(ray_color(scattered, depth - 1, world));

            if (rec.material.scatter(r, rec)) |t| {
                const scattered, const attenuation = t;
                return attenuation.mul(ray_color(scattered, depth - 1, world));
            }
            return Vec3F.zero();
        }

        const unit_dir = r.dir.normalize();
        const a = 0.5 * (unit_dir.y() + 1);
        return Vec3F.fill(1 - a).add(Vec3F{ .data = .{ a * 0.5, a * 0.7, a } });
    }
};
