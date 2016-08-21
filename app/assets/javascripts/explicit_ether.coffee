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

		p.expression = P.string('a + b')

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
			).map (args) => @generator.function(args...)
		p.toplevel = P.alt(p.fn)
		p.root = P.sepBy(p.toplevel, t.space)

	parse: (source) -> @generator.result(@parsers.root.parse(source))

class LoggingGenerator
	function: (args...) -> console.log('fn', args)
	result: (args...) -> console.log('result', args)

hex = (val, bytes) ->
	val_hex = val.toString(16)
	val_bytes = val_hex.length * 2
	if val_bytes > bytes
		throw "Value too big for buffer"
	else
		missing = bytes - val_bytes
		'0'.repeat(missing / 2).concat(val_hex)

hex32 = (val) ->  hex(val, 4)
hex64 = (val) -> hex(val, 8)
hex128 = (val) -> hex(val, 16)
hex256 = (val) -> hex(val, 32)

exports.utils =
	hex: hex
	hex32:  hex32
	hex64:  hex64
	hex128: hex128
	hex256: hex256

exports.EthOpCodesMap = op = {}
for idx, code of EthOpCodes
	name = code[0]
	if not op[name]
		op[name] =
			code: hex32(parseInt(idx))
			name: name
			fee: code[1]
			in: code[2]
			out: code[3]
			dynamic: code[4]

Instructions =
	add: -> [ EthOpCodesMap.ADD ]
	jump: (label) -> [ EthOpCodesMap.PUSH.code, { ref: label } ,hex32(EthOpCodesMap.JUMP.code)]
	push32: (val) -> [ EthOpCodesMap.PUSH.code, hex32(val) ]
	jumpDest:(label) -> [ { dest: label } ]


class EthereumGenerator
	constructor: () ->
		@opcodes = []
		@stack = []
		@random = 1000
		@labels = {}
		@emitJumpToMain()

	# Todo: namespace these somehow so they dont conflict with the handlers
	randomLabel: (context) ->
		@random += 1
		label("__anon_" + random, context)

	label: (name, context) ->
		if @labels[name]
			throw "Already defined name " + name
		@labels[name] = { name: name  }
		name

	emit: (code) ->
		@opcodes = @opcodes.concat(code)

	emitJumpToMain: ->
		@emit(Instructions.jump('main'))

	pushStack: -> @stack.push([])
	popStack: -> @stack.pop()

	resolveLabels: () ->
		# First pass scan all jump destinations
		count = 0
		for op,i in @opcodes
			if op.dest
				@opcodes[i] = EthOpCodesMap.JUMPDEST.code
				@labels[op.dest].position = count
				count += 4
			else if op.ref
				count += 4
			else
				count += op.length * 2

		# Second pass scan all jumps
		for op,i in @opcodes
			if op.ref
				if @labels[op.ref]
					@opcodes[i] = hex32(@labels[op.ref].position)
				else
					throw "Undefined label: " + op.ref

	# Generator handler functions:

	result: (result) ->
		if result.status
			@resolveLabels()
			result.code = @opcodes.join('')
		result

	function: (descriptor, body) ->
		[t, name, args, rtype] = descriptor
		[pre, post, result] = body

		@label(name)
		@emit(Instructions.jumpDest(name))
		# there's a stack that contains the code of the body

exports.ExplicitEther =
	Parser: Parser
	parse: (source) -> new Parser(new LoggingGenerator()).parse(source)
	generate: (source) -> new Parser(new EthereumGenerator()).parse(source)
