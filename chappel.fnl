
ns main

main = proc()
	import httprouter
	import stddbc
	import chappel-http
	import core
	import chapstore

	base = call(chapstore.new)
	call(get(base 'write') call(core.initial-data))

	routes = map(
		'GET' list(
				list(
					list('users')
					call(chappel-http.new-reader base core.get-users)
				)
				list(
					list('groups')
					call(chappel-http.new-reader base core.get-groups)
				)
				list(
					list('links')
					call(chappel-http.new-reader base core.get-links)
				)
				list(
					list('groups' ':id')
					call(chappel-http.new-get-all-groups-of-user base)
				)
				list(
					list('users' ':group-name')
					call(chappel-http.new-get-all-users-of-group base)
				)
				list(
					list('posts' ':id')
					call(chappel-http.new-get-posts-of-user base)
				)
			)

		'POST' list(
				list(
					list('users')
					call(chappel-http.new-add-handler base core.add-user)
				)
				list(
					list('groups')
					call(chappel-http.new-add-handler base core.add-group)
				)
				list(
					list('links')
					call(chappel-http.new-add-handler base core.add-link)
				)
				list(
					list('posts' ':group-name')
					call(chappel-http.new-add-post-to-group base)
				)
			)
	)

	my-error-logger = proc()
		import stdlog

		options = map(
			'prefix'       'my-HTTP-logger: '
			'separator'    ' : '
			'date'         true
			'time'         true
			'microseconds' true
			'UTC'          true
		)
		log = call(stdlog.get-default-logger options)
		proc(error-text)
			call(log error-text)
		end
	end

	router-info = map(
		'addr'         ':9903'
		'routes'       routes
		'error-logger' call(my-error-logger)
	)

	# create new router instance
	router = call(httprouter.new-router-v2 router-info)

	# get router procedures
	listen = get(router 'listen')
	shutdown = get(router 'shutdown')

	# signal handler for doing router shutdown
	import stdos
	sig-handler = proc(signum sigtext)
		print('signal received: ' signum sigtext)
		call(shutdown)
	end
	call(stdos.reg-signal-handler sig-handler 2)

	# wait and serve requests (until shutdown is made)
	print('...serving...')
	call(listen)
end

endns

