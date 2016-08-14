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

class Parser
	constructor: (@generator) ->
		# Parsers
		@parsers = p = {}

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
		p.body = p.statement.skip(t.semicolon).skip(t.space.many()).many()
		p.fn =
			P.seq(
				t.fn
					.skip(t.space),
				t.symbol, # function name
				p.arguments
					.skip(t.space).skip(t.arrow).skip(t.space), # function arguments
				p.type
					.skip(t.space).skip(t.lbrace).skip(t.space), # return type
				p.preconditions
					.skip(t.space),
				p.postconditions
					.skip(t.space),
				p.body
					.skip(t.rbrace)
			).map (args...) => @generator.function(args...)

		p.toplevel = P.alt(p.fn)
		p.root = P.sepBy(p.toplevel, t.space.many())

	parse: (source) -> @parsers.root.parse(source)

class LoggingGenerator
	function: (args...) -> console.log('fn', args)

exports.ExplicitEther =
	Parser: Parser
	parse: (source) -> new Parser(new LoggingGenerator()).parse(source)

