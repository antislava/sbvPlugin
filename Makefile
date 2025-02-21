# (c) Copyright Levent Erkok. All rights reserved.
#
# sbvPlugin is distributed with the BSD3 license. See the LICENSE file in the distribution for details.
SHELL     := /usr/bin/env bash
DEPSRCS   = $(shell find . -name '*.hs' -or -name '*.lhs' -or -name '*.cabal' | grep -v Paths_sbvPlugin.hs | grep -v dist-sandbox)
TESTSRCS  = $DEPSRCS
CABAL     = cabal
SIMPLIFY  = ./buildUtils/simplify
EXTRAOPTS = "--ghc-options=-Werror -Wall"

ifeq ($(shell uname -s),Darwin)
    TIME = /usr/bin/time caffeinate
else
    TIME = $$(which time)
endif

.PHONY: all install test vtest sdist clean docs gold hlint tags

all: install

install: $(DEPSRCS) Makefile
	@-ghc-pkg unregister --force sbvPlugin
	@(make -s -C buildUtils)
	@fast-tags -R --nomerge .
	@$(CABAL) configure --disable-library-profiling --enable-tests
	@(set -o pipefail; $(CABAL) build $(EXTRAOPTS) 2>&1 | $(SIMPLIFY))
	@$(CABAL) copy
	@$(CABAL) register

test: install
	$(TIME) $(CABAL) new-test
	@rm -rf tests/GoldFiles/*.current

vtest: install
	$(TIME) ./dist/build/sbvPluginTests/sbvPluginTests
	@rm -rf tests/GoldFiles/*.current

# use this as follows: make gold TGT=T49
gold:
	./dist/build/sbvPluginTests/sbvPluginTests -p ${TGT} --accept

sdist: install
	@(set -o pipefail; $(CABAL) sdist | $(SIMPLIFY))

veryclean: clean
	@-ghc-pkg unregister sbvPlugin

clean:
	@rm -rf dist

docs:
	@(set -o pipefail; $(CABAL) haddock --haddock-option=--no-warnings --hyperlink-source 2>&1 | $(SIMPLIFY))

release: clean checkLinks install sdist hlint docs vtest
	@echo "*** SBVPlugin is ready for release!"

hlint: 
	@rm -f hlintReport.html
	@echo "Running HLint.."
	@hlint Data tests -i "Use otherwise" -i "Use module export list"

checkLinks:
	@brok --no-cache --only-failures $(DEPSRCS) COPYRIGHT INSTALL LICENSE $(wildcard *.md)

tags:
	@fast-tags -R --nomerge .
