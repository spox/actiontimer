module ActionTimer

    class InvalidType < Exception
        attr_reader :given
        attr_reader :expected
        def initialize(g,e)
            @given = given
            @expected = e
        end

        def to_s
            "Given type: #{g} Expected type: #{e}"
        end
    end
end