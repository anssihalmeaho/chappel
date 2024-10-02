
ns main

import core
import stddbc
import sure
import stdfu

assert = stddbc.assert

test-add-user-ok = func()
	store = call(core.initial-data)
	ok err nstore = call(core.add-user store map('name' 'Ben')):

	call(assert ok err)
	call(assert
		in(get(nstore 'facts') list('user' 'Ben' '11'))
		sprintf('user not found: %v' nstore)
	)
end

test-invalid-user = func()
	store = call(core.initial-data)
	ok err nstore = call(core.add-user store map('no name given' 'Ben')):

	call(assert not(ok) 'should fail')
	call(assert
		eq(err 'invalid user info')
		sprintf('unexpected failure: %s' err)
	)
	call(assert eq(store nstore) 'store changed')
end

test-user-exist-already = func()
	store = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
	ok err _ = call(core.add-user store map('name' 'Ben')):
	call(assert not(ok) 'should fail')
end

test-add-group-ok = func()
	store = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
	ok err nstore = call(core.add-group store map('name' 'A-team' 'owner' 'Ben')):

	call(assert ok err)
	call(assert
		in(get(nstore 'facts') list('group' 'A-team' '11'))
		sprintf('group not found: %v' nstore)
	)
end

test-invalid-group = func()
	do-test = func(group-info assumed-reason)
		store = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
		ok err nstore = call(core.add-group store group-info):

		call(assert not(ok) 'should fail')
		call(assert
			eq(err assumed-reason)
			sprintf('unexpected failure: %s' err)
		)
		call(assert eq(store nstore) 'store changed')
	end

	and(
		call(do-test map('NO name' 'A-team' 'owner' 'Ben') 'invalid group info')
		call(do-test map('name' 'A-team' 'NO owner' 'Ben') 'invalid group info')
		call(do-test map('name' 'A/team' 'owner' 'Ben') 'invalid group name')
	)
end

test-group-exist-already = func()
	store = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
	store2 = call(sure.ok call(core.add-user store map('name' 'Bill')))
	store3 = call(sure.ok call(core.add-group store2 map('name' 'A-team' 'owner' 'Ben')))
	ok err store4 = call(core.add-group store3 map('name' 'A-team' 'owner' 'Bill')):

	call(assert not(ok) 'should fail')
	call(assert
		eq(err 'group exists already')
		sprintf('unexpected failure: %s' err)
	)
	call(assert eq(store3 store4) 'store changed')
end

test-group-owner-not-found = func()
	store = call(core.initial-data)
	ok err nstore = call(core.add-group store map('name' 'A-team' 'owner' 'Ben')):

	call(assert not(ok) 'should fail')
	call(assert
		eq(err 'group owner not found')
		sprintf('unexpected failure: %s' err)
	)
	call(assert eq(store nstore) 'store changed')
end

test-add-link-ok = func()
	store1 = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
	store2 = call(sure.ok call(core.add-group store1 map('name' 'A-team' 'owner' 'Ben')))
	store3 = call(sure.ok call(core.add-link store2 map('user' 'Ben' 'group' 'A-team')))

	call(assert
		in(get(store3 'facts') list('link' 'A-team' '11'))
		sprintf('link not found: %v' store3)
	)
end

test-invalid-link = func()
	do-test = func(link-info assumed-reason)
		store1 = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
		store2 = call(sure.ok call(core.add-group store1 map('name' 'A-team' 'owner' 'Ben')))
		ok err store3 = call(core.add-link store2 link-info):

		call(assert not(ok) 'should fail')
		call(assert
			eq(err assumed-reason)
			sprintf('unexpected failure: %s' err)
		)
		call(assert eq(store2 store3) 'store changed')
	end

	and(
		call(do-test map('NO user' 'Ben' 'group' 'A-team') 'invalid link info')
		call(do-test map('user' 'Ben' 'NO group' 'A-team') 'invalid link info')
		call(do-test map('user' 'Ben') 'invalid link info')
		call(do-test map('user' 'Ben' 'group' 'NO team') 'group does not exist')
		call(do-test map('user' 'NO user' 'group' 'A-team') 'user does not exist')
	)
end

test-same-link-exists-already = func()
	link-info = map('user' 'Ben' 'group' 'A-team')

	store1 = call(sure.ok call(core.add-user call(core.initial-data) map('name' 'Ben')))
	store2 = call(sure.ok call(core.add-group store1 map('name' 'A-team' 'owner' 'Ben')))
	store3 = call(sure.ok call(core.add-link store2 link-info))
	ok err store4 = call(core.add-link store3 link-info):

	call(assert not(ok) 'should fail')
	call(assert
		eq(err 'same link exists already')
		sprintf('unexpected failure: %s' err)
	)
	call(assert eq(store3 store4) 'store changed')
end

main = proc()
	passed = and(
		# user add tests
		call(test-add-user-ok)
		call(test-invalid-user)
		call(test-user-exist-already)

		# add group tests
		call(test-add-group-ok)
		call(test-invalid-group)
		call(test-group-exist-already)
		call(test-group-owner-not-found)

		# add link tests
		call(test-add-link-ok)
		call(test-invalid-link)
		call(test-same-link-exists-already)
	)
	if(passed 'Pass' 'Fail')
end

endns

