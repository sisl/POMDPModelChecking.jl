# Parse formulat
# allowed symbols
# Unary operator: !, F, G, X
# Binary operator: U, R , W, M
# translate with ltl2tgba
# property = "!crash U goal"

property = "(a U b) & GFb"
ltl2tgba(property, "test.hoa") # should translate to DBA
automata = hoa2buchi("test.hoa")


# property = "FGa"
# ltl2tgba(property, "test.hoa") # should translate to DRA
# automata = hoa2rabin("test.hoa")

# property = "Ga|Gb|Gc"

