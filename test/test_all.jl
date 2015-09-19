using StreamReader
using Base.Test

@test DEFAULT_PART_SIZE == 1024

pit = PartsIterator(10)
@test pit.size == 10
@test pit.part_size == DEFAULT_PART_SIZE
@test pit.left == 0
@test pit.length == 1
@test pit.part == 0
@test pit.current_size == 0

pit = PartsIterator(10, 3)

@test pit.size == 10
@test pit.part_size == 3
@test pit.left == 0
@test pit.length == 4
@test pit.part == 0
@test pit.current_size == 0

s = start(pit)
@test s == 3
@test pit.part_size == 3
@test pit.left == 10
@test pit.length == 4
@test pit.part == 0
@test pit.current_size == 0

@test !done(pit, s)
@test pit.part_size == 3
@test pit.left == 10
@test pit.length == 4
@test pit.part == 0
@test pit.current_size == 0

d, s = next(pit, s)
@test d == 3
@test s == 3
@test pit.part_size == 3
@test pit.left == 7
@test pit.length == 4
@test pit.part == 1
@test pit.current_size == 3

@test !done(pit, s)

d, s = next(pit, s)
@test d == 3
@test s == 3
@test pit.part_size == 3
@test pit.left == 4
@test pit.length == 4
@test pit.part == 2
@test pit.current_size == 3

@test !done(pit, s)

d, s = next(pit, s)
@test d == 3
@test s == 1
@test pit.part_size == 3
@test pit.left == 1
@test pit.length == 4
@test pit.part == 3
@test pit.current_size == 3

@test !done(pit, s)

d, s = next(pit, s)
@test d == 1
@test s == 0
@test pit.part_size == 3
@test pit.left == 0
@test pit.length == 4
@test pit.part == 4
@test pit.current_size == 1

@test done(pit, s)
@test [(1, 3, 7), (2, 3, 4), (3, 3, 1), (4, 1, 0)] == [(pit.part, d, pit.left) for d in pit]

