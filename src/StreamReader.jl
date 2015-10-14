module StreamReader

if VERSION < v"0.4.0-dev"
    using Docile
    eval(:(@docstrings(manual = ["../README.md"])))
end

export PartsIterator,
    ReaderIterator,
    IOReaderIterator,
    IOStringReaderIterator,
    ReaderListIterator,
    DEFAULT_PART_SIZE,
    loaded_pct,
    calculate

const DEFAULT_PART_SIZE = 1024

@doc """
Calculate sizes.
Return tuple of:
    1: Number of parts
    2: The parts size
    3: The last part size
""" ->
function calculate(total_size::Integer, part_size::Integer=0)
    part_size = (part_size == 0 ? DEFAULT_PART_SIZE : part_size)

    if part_size > total_size
        part_size = total_size
    end

    parts = convert(Integer, ceil(total_size / part_size))
    last_part_size = total_size % part_size
    if last_part_size == 0
        last_part_size = part_size
    end
    (parts, part_size, last_part_size)
end

@doc """
Iterator over parts
""" ->
type PartsIterator
    size::Integer
    part_size::Integer
    loaded::Integer
    length::Integer
    part::Integer
    current_size::Integer
    left::Integer
    last_part_size::Integer
    
    PartsIterator(s::Integer, ps::Integer = 0) = begin
        l, ps, lps = calculate(s, ps)
        new(s, ps, 0, l, 0, 0, 0, lps)
    end
end

Base.start(p::PartsIterator) = begin
    s = p.size < p.part_size ? p.size : p.part_size
    p.loaded = 0
    p.part = 0
    p.left = p.size
    s
end

Base.done(p::PartsIterator, state) = p.loaded == p.size

Base.length(p::PartsIterator) = p.length

Base.next(p::PartsIterator, state) = begin
    p.current_size = state
    p.left -= state
    p.part += 1
    p.loaded += state
    next_state = p.left < state ? p.left : state
    state, next_state
end

function loaded_pct(pi::PartsIterator)
    pi.loaded * 100 / pi.size
end

type ReaderIterator
    parts::PartsIterator
    pre_start::Union(Nothing,Function)
    post_done::Union(Nothing,Function)
    read::Union(Nothing,Function)
    iterating::Bool
    
    ReaderIterator(bp::PartsIterator; pre_start::Union(Nothing,Function) = nothing,
        post_done::Union(Nothing,Function) = nothing) = new(bp, pre_start, 
        post_done, nothing, false)
    ReaderIterator(ps::Function, bp::PartsIterator; kwargs...) = ReaderIterator(bp;
        pre_start=ps, kwargs...)
end

Base.start(sr::ReaderIterator) = begin
    state = start(sr.parts)
    
    if sr.pre_start != nothing
        sr.pre_start(sr)
    end

    sr.iterating = true
    
    return state
end

Base.done(ri::ReaderIterator, state) = begin
    d = done(ri.parts, state)

    if d && ri.iterating
        ri.iterating = false

        if ri.post_done != nothing
            ri.post_done(ri)
        end
    end

    return d
end

Base.next(ri::ReaderIterator, state) = begin
    ri.read(state), next(ri.parts, state)[2]
end

loaded(ri::ReaderIterator) = loaded(ri.parts)
loaded_pct(ri::ReaderIterator) = loaded_pct(ri.parts)

type ReaderListIterator
    make_reader::Function
    count::Integer
    num::Integer
    reader::Union(Nothing, ReaderIterator)

    ReaderListIterator(mr::Function, c::Integer) = new(mr, c, 0, nothing)
end

Base.start(ri::ReaderListIterator) = begin
    ri.num = 0
    ri.reader = nothing
    return 1
end

Base.done(ri::ReaderListIterator, state) = begin
    return state > ri.count
end

Base.next(ri::ReaderListIterator, state) = begin
    ri.num = state
    ri.reader = ri.make_reader(ri)
    (state, ri.reader), state+1
end

function set_data_type{T}(ri::ReaderIterator, data_type::Type{T})
    old_read = ri.read
    ri.read = (size) -> data_type(old_read(size))
end

function IOReaderIterator{T,D}(io::IO, bp::PartsIterator; read_type::Type{T} = Uint8,
    data_type::Type{D} = Nothing, pre_start::Union(Nothing,Function) = nothing, kwargs...)
    ReaderIterator(bp; kwargs...) do ri
        ri.read = (size) -> Base.read(io, read_type, size)

        if data_type != Nothing
            set_data_type(ri, data_type)
        end

        if pre_start != nothing
            pre_start(ri)
        end
    end
end

IOReaderIterator(io::IO, len::Integer, bsize::Integer=0; kwargs...) = IOReaderIterator(io,
    PartsIterator(len, bsize); kwargs...)

function IOStringReaderIterator{D<:String}(io::IO, pi::PartsIterator;
    data_type::Type{D} = UTF8String, kwargs...)
    IOReaderIterator(io, pi; data_type=data_type, kwargs...)
end

IOStringReaderIterator(io::IO, len::Integer, bsize::Integer=0; kwargs...) = IOStringReaderIterator(io,
    PartsIterator(len, bsize); kwargs...)

end
