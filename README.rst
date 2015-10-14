StreamReader.jl
===============

The Julia Stream Reader Interface and basic implementation.

.. image:: https://travis-ci.org/moisespsena/StreamReader.jl.svg?branch=master
    :target: https://travis-ci.org/moisespsena/StreamReader.jl


.. image:: https://coveralls.io/repos/moisespsena/StreamReader.jl/badge.svg?branch=master&service=github
  :target: https://coveralls.io/github/moisespsena/StreamReader.jl?branch=master



Install
-------

.. code-block:: julia

    Pkg.clone("https://github.com/moisespsena/StreamReader.jl.git")

    
Usage Example
-------------

Calculate
+++++++++

.. code-block:: julia

    using StreamReader
    num_parts, part_size, last_part_size = calculate(12345)
    num_parts, part_size, last_part_size = calculate(12345, 310) # max part size is 310


Iteration Example
+++++++++++++++++

.. code-block:: julia

    using StreamReader

    println("Default part size: $(DEFAULT_PART_SIZE)")

    io = IOBuffer()
    s = write(io, "God is Love!!")
    seekstart(io)

    ir = IOReaderIterator(io, s)
    println("1. With default part size ($(ir.parts.part_size) bytes):")

    for d in ir
        println("data part: '$(UTF8String(d))'")
    end

    seekstart(io)

    println("")

    part_size = 4

    println("2. Part size with $(part_size) bytes:")

    ir = IOReaderIterator(io, s, part_size)
    
    for d in ir
        println(string("data part [", ir.parts.part, " of ", ir.parts.length,
            " parts, at ", ir.parts.current_size , " part bytes, loaded ",
            ir.parts.loaded, " of ", ir.parts.size,
            " total bytes, ", ceil(loaded_pct(ir), 2), "%, left ", ir.parts.left ,
            " bytes) --> '", UTF8String(d), "'"))
    end