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
	space: P.alt(P.string(' ').desc('space'), P.string("\n"))
	symbol: P.regexp(/[a-zA-Z_-][a-zA-Z0-9_-]*/).desc('symbol')
	semicolon: P.string(';')
	arrow: P.string('->')

# Parsers
p = {}

# fn add(int a, int b) -> int {
#   pre {
#	  a >= 0
#     b >= 0
#   }
#   post {
#     if b > 0 then result > a
#     if a > 0 then result > b
#   }
#   return a + b
# }

p.arguments = P.string('()')
p.type = t.symbol
p.preconditions = P.string('pre {}')
p.postconditions = P.string('post {}')
p.statement = P.string('return a + b')
p.body = P.seq(p.statement, t.semicolon, t.space).many()
p.fn = t.fn.skip(t.space).then(
	P.seq(
		t.symbol, # function name
		p.arguments, # function arguments
		t.space,
		t.arrow,
		t.space,
		p.type, # return type
		t.space,
		t.lbrace,
		t.space,
		p.preconditions, # 
		t.space,
		p.postconditions, # 
		t.space,
		p.body, #
		t.rbrace,
		t.space
	).then(
#		(_1, args, _2, _3, _10, type, _4, _5, _11, pre, _6, post, _7, body, _8, _9) -> [
#			 args, type, pre, post, body
#		]
#	)
)

class Parser
	constructor: (@source) ->
	parse: () -> @root.parse(@source)
	root: p.fn.map () -> debugger

exports.ExplicitEther =
	Parser: Parser
	parse: (source) -> new Parser(source).parse()

