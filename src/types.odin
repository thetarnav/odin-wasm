package hive

ID_LENGTH :: 8
Id :: struct {
    bytes: [ID_LENGTH]byte
}

Post :: struct {
	author:    Id,
	timestamp: i64,
	content:   string,
}
