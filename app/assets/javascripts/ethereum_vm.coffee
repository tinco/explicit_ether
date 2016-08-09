# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

App.EthereumVM =
	parseSource: () ->
		console.log 'Parsing source...'
		source = $('#source').val()
		

	runBinary: () ->
		console.log 'Running binary...'
		binary = $('#binary').val()
		vm = new EthVm()
		code = new Buffer(binary, 'hex')

		vm.on 'step', (data) -> 
			console.log('Step..')
			$('#vmSteps').append('<li>' + data.opcode.name + '</li>')

		$('#vmSteps').html("")

		vm.runCode(
			{
				code: code,
				gasLimit: new Buffer('ffffffff', 'hex')
			}, (err, results) ->
				console.log('Got results..')
				$('#result').text(results.return.toString('hex'))
				$('#gasUsed').text(results.gasUsed.toString())
		)