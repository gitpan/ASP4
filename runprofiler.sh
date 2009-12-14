#!/bin/sh

rm -rf ./nytprof ./nytprof.out
PERL5OPT=-MDevel::NYTProf prove t -r
nytprofhtml

