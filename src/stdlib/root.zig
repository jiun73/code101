const C = @cImport({
    @cInclude("/usr/include/espeak-ng/speak_lib.h");
    @cInclude("stdlib.h");
});
const std = @import("std");

var is_init = false;
const default_voice = "mb-ca2";

pub fn init() void {
    _ = C.espeak_Initialize(
        C.AUDIO_OUTPUT_SYNCH_PLAYBACK,
        500,
        null,
        5,
    );
    _ = C.espeak_SetParameter(C.espeakRATE, 100, 0);
    _ = C.espeak_SetVoiceByName(default_voice);
    is_init = true;
}

export fn say(text: [*:0]const u8) void {
    if (!is_init) {
        init();
    }
    _ = C.espeak_Synth(text, std.mem.len(text), 0, 0, 0, C.espeakCHARS_UTF8, null, null);
}

export fn print_bool(v: bool) void {
    _ = C.printf("%s\n", if (v) "vrai" else "faux");
}

export fn say_double(v: f64) void {
    if (!is_init) {
        init();
    }

    var buffer: [1024]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "{}", .{v}) catch @panic("Erreur dans l'affichage de la valeur");

    _ = C.espeak_Synth(text.ptr, text.len, 0, 0, 0, C.espeakCHARS_UTF8, null, null);
}

export fn read_double(var_name: [*:0]const u8) f64 {
    var buffer: [1024]u8 = undefined;
    _ = C.printf("%s: ", var_name);
    _ = C.fflush(C.stdout);
    var stdin = std.fs.File.stdin().reader(&buffer);
    const line = stdin.interface.takeDelimiterExclusive('\n') catch @panic("Impossible de lire l'entrée standard");
    const trimmed = std.mem.trimRight(u8, line, "\r");

    return std.fmt.parseFloat(f64, trimmed) catch @panic("Valeur invalide !!!");
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    _ = C.printf("Panique !! \n%.*s\n", @as(c_int, @intCast(msg.len)), msg.ptr);
    C.exit(1);
}
