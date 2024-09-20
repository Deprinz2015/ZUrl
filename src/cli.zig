const zli = @import("zli");

pub fn main() !void {
    try zli.generateParser(.{
        .options = .{
            .help = .{ .type = bool, .short = 'h', .desc = "Print this help/usage message." },
            .db = .{ .type = []const u8, .desc = "Path to the sqlite file.", .value_hint = "PATH" },
            .port = .{
                .type = u16,
                .short = 'p',
                .desc = "Port number, on which the server to run on.",
                .default = 8080,
                .value_hint = "PORT",
            },
        },
    });
}
