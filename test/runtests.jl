using StreamReader
using FactCheck

facts("All") do
    @fact DEFAULT_PART_SIZE --> 1024
    @fact calculate(10) --> (1, 10, 10)
    @fact calculate(10, 3) --> (4, 3, 1)
    @fact calculate(1024) --> (1, 1024, 1024)
    @fact calculate(2048) --> (2, 1024, 1024)
    @fact calculate(2024) --> (2, 1024, 1000)

    pit = PartsIterator(10)
    @fact pit.size --> 10
    @fact pit.part_size --> 10
    @fact pit.left --> 0
    @fact pit.length --> 1
    @fact pit.part --> 0
    @fact pit.current_size --> 0
    @fact pit.loaded --> 0

    pit = PartsIterator(10, 3)

    @fact pit.size --> 10
    @fact pit.part_size --> 3
    @fact pit.left --> 0
    @fact pit.length --> 4
    @fact pit.part --> 0
    @fact pit.current_size --> 0
    @fact pit.loaded --> 0

    s = start(pit)
    @fact s --> 3
    @fact pit.part_size --> 3
    @fact pit.left --> 10
    @fact pit.length --> 4
    @fact pit.part --> 0
    @fact pit.current_size --> 0
    @fact pit.loaded --> 0

    @fact done(pit, s) --> false
    @fact pit.part_size --> 3
    @fact pit.left --> 10
    @fact pit.length --> 4
    @fact pit.part --> 0
    @fact pit.current_size --> 0
    @fact pit.loaded --> 0

    d, s = next(pit, s)
    @fact d --> 3
    @fact s --> 3
    @fact pit.part_size --> 3
    @fact pit.left --> 7
    @fact pit.length --> 4
    @fact pit.part --> 1
    @fact pit.current_size --> 3
    @fact pit.loaded --> 3

    @fact done(pit, s) --> false

    d, s = next(pit, s)
    @fact d --> 3
    @fact s --> 3
    @fact pit.part_size --> 3
    @fact pit.left --> 4
    @fact pit.length --> 4
    @fact pit.part --> 2
    @fact pit.current_size --> 3
    @fact pit.loaded --> 6

    @fact done(pit, s) --> false

    d, s = next(pit, s)
    @fact d --> 3
    @fact s --> 1
    @fact pit.part_size --> 3
    @fact pit.left --> 1
    @fact pit.length --> 4
    @fact pit.part --> 3
    @fact pit.current_size --> 3
    @fact pit.loaded --> 9

    @fact done(pit, s) --> false

    d, s = next(pit, s)
    @fact d --> 1
    @fact s --> 0
    @fact pit.part_size --> 3
    @fact pit.left --> 0
    @fact pit.length --> 4
    @fact pit.part --> 4
    @fact pit.current_size --> 1
    @fact pit.loaded --> 10

    @fact done(pit, s) --> true
    @fact [(1, 3, 3, 7, 30.0), (2, 3, 6, 4, 60.0), (3, 3, 9, 1, 90.0), (4, 1, 10, 0, 100.0)] --> [(pit.part, d, pit.loaded, pit.left, ceil(loaded_pct(pit), 2)) for d in pit]

    #### READER ITERATOR TEST #####

    io = IOBuffer()
    s = write(io, "God is Love!!")
    seekstart(io)
    ir = IOStringReaderIterator(io, s, 4)
    edata = String["God ", "is L", "ove!", "!"]
    data = collect(ir)
    @fact edata --> data

    #### READER LIST ITERATOR TEST #####
    
    data = "God is Love!!"
    io = IOBuffer()
    s = write(io, data)
    seekstart(io)
    num_parts, parts_size, last_part_size = calculate(s, 4)
    parts_size_arr = Integer[parts_size for i in 1:num_parts-1]
    push!(parts_size_arr, last_part_size)

    edata = {{"Go", "d "}, {"is", " L"}, {"ov", "e!"}, {"!"}}

    rli = ReaderListIterator((mri) -> IOStringReaderIterator(io, parts_size_arr[mri.num], 2), num_parts)
    for (num, sri) in rli
        for d in sri
            @fact d --> edata[num][sri.num] "Mismatch edata[$num][$(sri.num)]"
        end
    end
end
