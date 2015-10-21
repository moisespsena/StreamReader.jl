module StreamReader

export PartsIterator,
    ReaderIterator,
    IOReaderIterator,
    IOStringReaderIterator,
    ReaderListIterator,
    DEFAULT_PART_SIZE,
    loadedpct,
    calculate

const DEFAULT_PART_SIZE = 1024
const N = Void
const N_TYPE = Type{N}
const STR_TYPE = isdefined(:AbstractString)? AbstractString : String

"""
Calculate sizes.
Return tuple of:
    1: Number of parts
    2: The parts size
    3: The last part size
"""
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

"""
Iterator over parts
"""
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

function loadedpct(pi::PartsIterator)
    pi.loaded * 100 / pi.size
end

type ReaderIterator
    parts::PartsIterator
    prestart::Union(N_TYPE,Function)
    postdone::Union(N_TYPE,Function)
    read::Union(N_TYPE,Function)
    iterating::Bool
    num::Integer
    
    ReaderIterator(bp::PartsIterator; prestart::Union(N_TYPE,Function) = N,
        postdone::Union(N_TYPE,Function) = N) = new(bp, prestart, 
        postdone, N, false, 0)
    ReaderIterator(ps::Function, bp::PartsIterator; kwargs...) = ReaderIterator(bp;
        prestart=ps, kwargs...)
end

Base.start(sr::ReaderIterator) = begin
    state = start(sr.parts)
    
    if sr.prestart != N
        sr.prestart(sr)
    end

    sr.iterating = true
    sr.num = 0
    
    return state
end

Base.done(ri::ReaderIterator, state) = begin
    d = done(ri.parts, state)

    if d && ri.iterating
        ri.iterating = false

        if ri.postdone != N
            ri.postdone(ri)
        end
    end

    return d
end

Base.next(ri::ReaderIterator, state) = begin
    ri.num += 1
    ri.read(state), next(ri.parts, state)[2]
end

loaded(ri::ReaderIterator) = loaded(ri.parts)
loadedpct(ri::ReaderIterator) = loadedpct(ri.parts)

type ReaderListIterator
    makereader::Function
    count::Integer
    num::Integer
    reader::Union(N_TYPE, ReaderIterator)

    ReaderListIterator(mr::Function, c::Integer) = new(mr, c, 0, N)
end

Base.start(ri::ReaderListIterator) = begin
    ri.num = 0
    ri.reader = N
    return 1
end

Base.done(ri::ReaderListIterator, state) = begin
    return state > ri.count
end

Base.next(ri::ReaderListIterator, state) = begin
    ri.num = state
    ri.reader = ri.makereader(ri)
    (state, ri.reader), state+1
end

function setdatatype{T}(ri::ReaderIterator, datatype::Type{T})
    oldread = ri.read
    ri.read = (size) -> datatype(oldread(size))
end

function IOReaderIterator{T,D}(io::IO, bp::PartsIterator; read_type::Type{T} = Uint8,
    datatype::Type{D} = N_TYPE, prestart::Union(N_TYPE,Function) = N, kwargs...)
    ReaderIterator(bp; kwargs...) do ri
        ri.read = (size) -> Base.read(io, read_type, size)

        if datatype != N_TYPE
            setdatatype(ri, datatype)
        end

        if prestart != N
            prestart(ri)
        end
    end
end

IOReaderIterator(io::IO, len::Integer, bsize::Integer=0; kwargs...) = IOReaderIterator(io,
    PartsIterator(len, bsize); kwargs...)

function IOStringReaderIterator{D<:STR_TYPE}(io::IO, pi::PartsIterator;
    datatype::Type{D} = UTF8String, kwargs...)
    IOReaderIterator(io, pi; datatype=datatype, kwargs...)
end

IOStringReaderIterator(io::IO, len::Integer, bsize::Integer=0; kwargs...) = IOStringReaderIterator(io,
    PartsIterator(len, bsize); kwargs...)

end
