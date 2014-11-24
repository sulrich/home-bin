#!/usr/bin/env bash

export PERLBREW_ROOT=${HOME}/src/perl
export PERLBREW_HOME=${HOME}/.perlbrew
source ${PERLBREW_ROOT}/etc/bashrc

read input


perlbrew use 5.18.4
cat $input | perl -MText::Autoformat -e "{autoformat{all=>1,right=>80,tabspace=>2};}"
