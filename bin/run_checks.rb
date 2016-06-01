#!/usr/bin/env ruby

lib = File.join(File.dirname(__FILE__), '../lib/')
$:.unshift lib unless $:.include?(lib)

require 'checker'

exit CheckRunner.new(ENV, *ARGV).run
