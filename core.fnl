
ns core

#import stdpp
import stdmeta
import stdfu
import loqic
import lens

# initial data content
initial-data = func()
	map(
		'user-id-counter' 10
		'facts'           list()
		'posts'           map()
	)
end

# get all messages for given user-id
get-posts-of-user = func(store user-id)
	found users-posts = call(lens.get-from list('posts' user-id) store):
	if(found
		call(func()
			next-value = call(lens.set-to list('posts' user-id) store list())
			list(users-posts next-value)
		end)
		list(list() store)
	)
end

# add message for given group
add-post = func(store group-name post)
	add-to-one-user = func(uid posts)
		if(in(posts uid)
			call(func()
				prev-posts = get(posts uid)
				put(del(posts uid) uid append(prev-posts post))
			end)

			put(posts uid list(post))
		)
	end

	is-valid-post = func(posting)
		post-schema = list('map' map(
			'msg' list(list('required') list('type' 'string') list('doc' 'message in posting'))
		))
		ok _ = call(stdmeta.validate post-schema posting):
		ok
	end

	# TODO: validate post format
	cond(
		# validating input post data
		not(call(is-valid-post post))
		list(false 'invalid post' store)

		call(func()
			matches = call(loqic.match
				list('and'
					list('user' '?user-name' '?uid')
					list('link' group-name '?uid')
				)
				get(store 'facts')
			)
			user-ids = call(stdfu.apply matches func(item) get(item 'uid') end)

			new-posts = call(stdfu.foreach user-ids add-to-one-user get(store 'posts'))
			next-value = call(lens.set-to list('posts') store new-posts)
			list(true '' next-value)
		end)
	)
end

# give all groups to which user (by user-id) belongs to
get-all-groups-of-user = func(store user-id)
	matches = call(loqic.match
		list('and'
			list('user' '?user-name' user-id)
			list('link' '?gr-name' user-id)
		)
		get(store 'facts')
	)
	call(stdfu.apply matches func(item) get(item 'gr-name') end)
end

# give all users which belong to given group
get-all-users-of-group = func(store group-name)
	matches = call(loqic.match
		list('and'
			list('user' '?user-name' '?uid')
			list('link' group-name '?uid')
		)
		get(store 'facts')
	)
	call(stdfu.apply matches func(item)
		map(
			'name' get(item 'user-name')
			'id'   get(item 'uid')
		)
	end)
end

get-users = func(store)
	facts = get(store 'facts')
	users = call(loqic.match list('user' '?name' '?uid') facts)
	call(stdfu.pairs-to-map call(stdfu.apply users func(item)
		list(
			get(item 'uid') map(
				'name' get(item 'name')
				'id'   get(item 'uid')
			)
		)
	end))
end

get-groups = func(store)
	facts = get(store 'facts')
	groups = call(loqic.match list('group' '?gr-name' '?owner-id') facts)
	call(stdfu.pairs-to-map call(stdfu.apply groups func(item)
		list(
			get(item 'gr-name') map(
				'name' get(item 'gr-name')
				'id'   get(item 'owner-id')
			)
		)
	end))
end

get-links = func(store)
	facts = get(store 'facts')
	links = call(loqic.match list('link' '?gr-name' '?uid') facts)
	call(stdfu.apply links func(item)
		 map(
			'group' get(item 'gr-name')
			'user'  get(item 'uid')
		)
	end)
end

# add link between user and group (adding user to group)
add-link  = func(store link-info)
	facts = get(store 'facts')

	# validates data format for link
	is-valid-link-info = func(link)
		link-schema = list('map' map(
			'user' list(list('required') list('type' 'string') list('doc' 'Users name'))
			'group' list(list('required') list('type' 'string') list('doc' 'Group name'))
		))
		ok _ = call(stdmeta.validate link-schema link):
		ok
	end

	cond(
		# validating input user data
		not(call(is-valid-link-info link-info))
		list(false 'invalid link info' store)

		# checking that such group exists
		empty(call(loqic.match list('group' get(link-info 'group') '?owner-id') facts))
		list(false 'group does not exist' store)

		call(func()
			user-matches = call(loqic.match list('user' get(link-info 'user') '?uid') facts)
			if(empty(user-matches)
				list(false 'user does not exist' store)

				call(func()
					new-link = list('link' get(link-info 'group') get(head(user-matches) 'uid'))
					if(empty(call(loqic.match new-link facts))
						# ok, just add
						call(func()
							new-store = call(lens.set-to list('facts') store append(facts new-link))
							list(true '' new-store)
						end)

						list(false 'same link exists already' store)
					)
				end)
			)
		end)
	)
end

# add new group
add-group = func(store group-info)
	facts = get(store 'facts')

	# validates data format for group
	is-valid-group-info = func(group)
		group-schema = list('map' map(
			'name' list(list('required') list('type' 'string') list('doc' 'Group name'))
			'owner' list(list('required') list('type' 'string') list('doc' 'Group owner name'))
		))
		ok _ = call(stdmeta.validate group-schema group):
		ok
	end

	# validates group name
	is-valid-group-name = func(groupname)
		import stdstr

		call(stdfu.chain groupname list(
			func(s) call(stdstr.replace s '-' '') end
			func(s) call(stdstr.replace s '_' '') end
			func(s) call(stdstr.is-alpha s) end
		))
	end

	group-exists = func(new-group-name)
		not(empty(
			call(loqic.match list('group' new-group-name '?owner-id') facts)
		))
	end

	find-owner-id = func(owner)
		matched-users = call(loqic.match list('user' owner '?uid') facts)
		case(len(matched-users)
			0 list(false '')
			1 list(true get(head(matched-users) 'uid'))
			error('owner found multiple times: should not happen')
		)
	end

	cond(
		# validating input group data
		not(call(is-valid-group-info group-info))
		list(false 'invalid group info' store)

		# validating group name
		not(call(is-valid-group-name let(group-name get(group-info 'name'))))
		list(false 'invalid group name' store)

		# preventing same group name existing twice
		call(group-exists group-name)
		list(false 'group exists already' store)

		# ok lets add
		call(func()
			owner-found owner-id = call(find-owner-id get(group-info 'owner')):
			if(owner-found
				call(func()
					new-facts = append(facts list('group' group-name owner-id))
					new-store = call(lens.set-to list('facts') store new-facts)
					list(true '' new-store)
				end)
				list(false 'group owner not found' store)
			)
		end)
	)
end

add-user = func(store user-info)
	facts = get(store 'facts')

	# validates data format for user
	is-valid-user-info = func(user)
		user-schema = list('map' map(
			'name' list(list('required') list('type' 'string') list('doc' 'Users name'))
		))
		ok _ = call(stdmeta.validate user-schema user):
		ok
	end

	has-user = func(username)
		empty(call(loqic.match list('user' username '?uid') facts))
	end

	cond(
		# validating input user data
		not(call(is-valid-user-info user-info))
		list(false 'invalid user info' store)

		# verify that user with given name doesnt yet exist
		not(call(has-user get(user-info 'name')))
		list(false 'user exists already' store)

		# ok lets add
		call(func()
			prev-user-id = get(store 'user-id-counter')
			next-uid = plus(prev-user-id 1)
			next-uid-str = str(next-uid)

			username = get(user-info 'name')
			new-facts = append(facts list('user' username next-uid-str))

			new-store = map(
				'user-id-counter' next-uid
				'facts'           new-facts
				'posts'           get(store 'posts')
			)
			list(true '' new-store)
		end)
	)
end

endns

