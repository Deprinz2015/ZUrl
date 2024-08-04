const std = @import("std");
const c = @cImport(
    @cInclude("sqlite3.h"),
);

const DB_FILE = "data/urls.db";

pub fn main() !void {
    var db: ?*c.sqlite3 = null;
    const open_db = c.sqlite3_open(DB_FILE, &db);
    if (open_db != 0) {
        std.debug.print("Could not open db: {s}\n", .{c.sqlite3_errmsg(db)});
    }
    defer _ = c.sqlite3_close(db);

    std.debug.print("Finished\n", .{});
}
