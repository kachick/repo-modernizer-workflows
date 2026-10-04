.PHONY: default compile check

default: compile

compile:
	gh-aw compile

check:
	gh-aw compile --strict --no-emit
