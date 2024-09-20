const zli = @import("zli");

const DEFAULT_DB_FILE = "data/urls.db";
const DEFAULT_PORT = 8080;

pub fn main() !void {
    try zli.generateParser(.{
        .options = .{
            .help = .{ .type = bool, .short = 'h', .desc = "Print this help/usage message." },
            .db = .{
                .type = []const u8,
                .default = DEFAULT_DB_FILE,
                .value_hint = "PATH",
                .desc = "Path to the sqlite file.",
            },
            .port = .{
                .type = u16,
                .short = 'p',
                .default = DEFAULT_PORT,
                .value_hint = "PORT",
                .desc = "Port number, on which the server to run on.",
            },
        },
    });
}
