
ns chapstore

new = proc()
	import stdvar
	container = call(stdvar.new map())

	map(
		'write'
		proc(val)
			call(stdvar.set container val)
		end

		'read'
		proc()
			call(stdvar.value container)
		end
	)
end

endns

