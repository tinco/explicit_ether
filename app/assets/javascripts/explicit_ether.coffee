exports = window

# dsl style alias
P = Parsimmon

# Tokens
t =
	fn: P.string('fn').desc('function keyword')
	lbrace: P.string('{').desc('left curly brace')
	rbrace: P.string('}').desc('right curly brace')
	lparen: P.string('(').desc('left parenthesis')
	rparen: P.string(')').desc('right parenthesis')
	space: P.string(' ').desc('space')
	symbol: P.regexp(/[a-zA-Z_-][a-zA-Z0-9_-]*/).desc('symbol')

# Parsers
p = {}

# fn add(int a, int b) -> int
#   pre {
#	  a >= 0
#     b >= 0
#   }
#   post {
#     if b > 0 then result > a
#     if a > 0 then result > b
#   }
#   do {
#     return a + b;
#   }
p.fn = t.fn.skip(t.space).then(t.symbol)

class Parser
	constructor: (@source) ->

	parse: () -> @root.parse(@source)
	root: p.fn.map (name) -> name

exports.ExplicitEther =
	Parser: Parser
	parse: (source) -> new Parser(source).parse()

