module StreamReader

export BufferParts,
    Reader,
    IOReader

type BufferParts
    size::Integer
    part_size::Integer
    left::Integer
    length::Integer
    part::Integer
    current_size::Integer
    
    BufferParts(l::Integer, ps::Integer = 1024) = new(l, ps, 0, 0, 0, 0)
end

Base.start(p::BufferParts) = begin
    s = p.size < p.part_size ? p.size : p.part_size
    p.left = p.size - s
    p.length = convert(Integer, ceil(p.size / p.part_size))
    p.part = 0
    s
end

Base.done(p::BufferParts, state) = begin
    state == 0 
end

Base.length(p::BufferParts) = p.length

Base.next(p::BufferParts, state) = begin
    p.current_size = state
    next_state = p.left < state ? p.left : state
    p.part += 1
    p.left -= next_state
    state, next_state
end

type Reader
    parts::BufferParts
    pre_start::Union(Nothing,Function)
    post_done::Union(Nothing,Function)
    read::Union(Nothing,Function)
    
    Reader(bp::BufferParts, ps::Union(Nothing,Function) = nothing, pd::Union(Nothing,Function) = nothing) = new(bp, ps, pd, nothing)
    Reader(ps::Function, bp::BufferParts, pd::Union(Nothing,Function) = nothing) = Reader(bp, ps, pd)
end

Base.start(sr::Reader) = begin
    state = start(sr.parts)
    
    if sr.pre_start != nothing
        sr.pre_start(sr)
    end
    
    return state
end

Base.done(sr::Reader, state) = done(sr.parts, state)

Base.next(sr::Reader, state) = begin
    sr.read(state), next(sr.parts, state)[2]
end


function IOReader(io::IO, bp::BufferParts; pre_start::Union(Nothing,Function) = nothing, kwargs...)
    Reader(bp; kwargs...) do sr
        sr.read = (size) -> Base.readbytes(io, size)
        if pre_start != nothing
            pre_start(sr)
        end
    end
end

IOReader(io::IO, len::Integer, bsize::Integer=1024; kwargs...) = IOReader(io, BufferParts(len, bsize); kwargs...)

end
