const std = @import("std");
const c = @cImport(
    @cInclude("sqlite3.h"),
);

const Error = error{
    CouldNotOpen,
};

const DB = @This();

db: ?*c.sqlite3 = null,

pub fn open_db(self: *DB, db_file: []const u8) !void {
    const rc = c.sqlite3_open(db_file.ptr, &self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
        return Error.CouldNotOpen;
    }
}

pub fn deinit(self: *DB) void {
    const rc = c.sqlite3_close(self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
    }
}
