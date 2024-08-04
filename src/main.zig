const std = @import("std");
const DB = @import("DB.zig");

const DB_FILE = "data/urls.db";

pub fn main() !void {
    var db: DB = .{};
    defer db.deinit();

    try db.open_db(DB_FILE);
    try db.createDbIfNotExists();

    std.debug.print("Finished\n", .{});
}
