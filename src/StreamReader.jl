module StreamReader

export PartsIterator,
    ReaderIterator,
    IOReaderIterator,
    ReaderListIterator,
    DEFAULT_PART_SIZE

const DEFAULT_PART_SIZE = 1024


type PartsIterator
    size::Integer
    part_size::Integer
    left::Integer
    length::Integer
    part::Integer
    current_size::Integer
    _left::Integer
    
    PartsIterator(s::Integer, ps::Integer = 0) = begin
        ps = (ps == 0 ? DEFAULT_PART_SIZE : ps)
        new(s, ps, 0,
        convert(Integer, ceil(s / ps)), 0, 0, 0)
    end
end

Base.start(p::PartsIterator) = begin
    s = p.size < p.part_size ? p.size : p.part_size
    p.left = p.size
    p._left = p.size - s
    p.part = 0
    s
end

Base.done(p::PartsIterator, state) = begin
    state == 0 
end

Base.length(p::PartsIterator) = p.length

Base.next(p::PartsIterator, state) = begin
    p.current_size = state
    next_state = p._left < state ? p._left : state
    p.part += 1
    p.left -= state
    p._left -= next_state
    state, next_state
end

type ReaderIterator
    parts::PartsIterator
    pre_start::Union(Nothing,Function)
    post_done::Union(Nothing,Function)
    read::Union(Nothing,Function)
    iterating::Bool
    
    ReaderIterator(bp::PartsIterator; pre_start::Union(Nothing,Function) = nothing, post_done::Union(Nothing,Function) = nothing) = new(bp, pre_start, post_done, nothing, false)
    ReaderIterator(ps::Function, bp::PartsIterator; kwargs...) = ReaderIterator(bp; pre_start=ps, kwargs...)
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

Base.next(sr::ReaderIterator, state) = begin
    sr.read(state), next(sr.parts, state)[2]
end

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

function IOReaderIterator(io::IO, bp::PartsIterator; pre_start::Union(Nothing,Function) = nothing, kwargs...)
    ReaderIterator(bp; kwargs...) do sr
        sr.read = (size) -> Base.readbytes(io, size)
        if pre_start != nothing
            pre_start(sr)
        end
    end
end

IOReaderIterator(io::IO, len::Integer, bsize::Integer=1024; kwargs...) = IOReaderIterator(io, PartsIterator(len, bsize); kwargs...)

end
