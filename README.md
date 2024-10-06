# chappel
Yet another messaging application example

## Installing
Fetch repository with `--recursive` option (so that needed submodules are included):

```
git clone --recursive https://github.com/anssihalmeaho/chappel
```

## Purpose
Functionally **chappel** is similar to [chapp example](https://github.com/anssihalmeaho/chapp).
It's very simplistic example of messaging/chat application (backend) implemented with [FunL programming language](https://github.com/anssihalmeaho/funl). 

It's structured in **Functional Core, Imperative Shell** pattern way:
1) HTTP handling in impure part (chappel.fnl/chappel-http.fnl)
2) domain code logic in pure functional part (core.fnl)

Purpose is to demonstrate how pure domain logic can be expressed partly in logic programming way (facts and queries).

## Notes
Some things to note:

* data storage is just overly simple in-memory store mock
* there are also unit tests for domain core logic (**coretest.fnl**)

## Running chappel
Start chappel:

```
funla chappel.fnl
```

Run integration tests:

```
funla verifier.fnl
```

## Running domain core logic unit tests

Run core unit tests:

```
funla coretest.fnl
```
