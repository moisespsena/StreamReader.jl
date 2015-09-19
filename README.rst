StreamReader.jl
===============

The Julia Stream Reader Interface and basic implementation.

Install
-------

.. code-block:: julia

    Pkg.clone("https://github.com/moisespsena/StreamReader.jl.git")

    
Usage Example
-------------

.. code-block:: julia

    using StreamReader

    println(@sprintf "Default part size: %s" DEFAULT_PART_SIZE)

    open("test-data.txt", "w+") do f
        s = write(f, "God is Love!!")
        seekstart(f)

        ir = IOReaderIterator(f, s)
        println(@sprintf "1. With default part size (%s bytes):" ir.parts.part_size)

        for d in ir
            println(@sprintf "data part: '%s'" UTF8String(d))
        end

        seekstart(f)

        println("")

        part_size = 4

        println(@sprintf "2. Part size with %s bytes:" part_size)

        ir = IOReaderIterator(f, s, part_size)

        for d in ir
            println(@sprintf "data part [%s of %s parts, at %s bytes] --> '%s'"
                ir.parts.part ir.parts.length ir.parts.current_size
                UTF8String(d))
        end
    end
