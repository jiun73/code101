pub fn isoneof(char: u8, list: []const u8) bool {
    var i: usize = 0;
    while (i < list.len) {
        if (char == list[i]) return true;
        i += 1;
    }
    return false;
}
