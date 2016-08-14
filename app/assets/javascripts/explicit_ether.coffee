exports = window

class Parser
	constructor: (@generator) ->
		# dsl style alias
		P = Parsimmon

		# Tokens
		@tokens = t =
			fn: P.string('fn').desc('function keyword')
			lbrace: P.string('{').desc('left curly brace')
			rbrace: P.string('}').desc('right curly brace')
			lparen: P.string('(').desc('left parenthesis')
			rparen: P.string(')').desc('right parenthesis')
			space: P.alt(P.string(' ').desc('space'), P.string("\n").desc('end-of-line')).atLeast(1)
			symbol: P.regexp(/[a-zA-Z_-][a-zA-Z0-9_-]*/).desc('symbol')
			semicolon: P.string(';')
			arrow: P.string('->')

		# Parsers
		@parsers = p = {}

		introducedBlock = (intro, body) ->
			P.seq(
				intro.skip(t.space).skip(t.lbrace).skip(t.space),
				P.alt(
					body.skip(t.space).skip(t.rbrace),
					P.string('').skip(t.rbrace)
				)
			)
		p.preconditions = introducedBlock(P.string('pre'), P.string(''))
		p.postconditions = introducedBlock(P.string('post'), P.string(''))
		p.expression = P.string('a + b')
		p.result = introducedBlock(P.string('result'), p.expression)
		p.arguments = P.string('()')
		p.type = t.symbol

		# fn add(int a, int b) -> int {
		#   pre {
		#	  a >= 0
		#     b >= 0
		#   }
		#   post {
		#     if b > 0 then result > a
		#     if a > 0 then result > b
		#   }
		#   result {
		#     a + b
		#   }
		# }
		p.fn =
			introducedBlock(
				P.seq(
					t.fn
						.skip(t.space),
					t.symbol, # function name
					p.arguments
						.skip(t.space).skip(t.arrow).skip(t.space), # function arguments
					p.type # return type
				),
				P.seq(
					p.preconditions
						.skip(t.space),
					p.postconditions
						.skip(t.space),
					p.result
				)
			).map (args...) => @generator.function(args...)
		p.toplevel = P.alt(p.fn)
		p.root = P.sepBy(p.toplevel, t.space)

	parse: (source) -> @generator.result(@parsers.root.parse(source))

class LoggingGenerator
	function: (args...) -> console.log('fn', args)
	result: (args...) -> console.log('result', args)

exports.ExplicitEther =
	Parser: Parser
	parse: (source) -> new Parser(new LoggingGenerator()).parse(source)

