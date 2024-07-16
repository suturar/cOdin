#!/usr/bin/sh
set -xe

odin build . -error-pos-style:unix -debug -show-timings
