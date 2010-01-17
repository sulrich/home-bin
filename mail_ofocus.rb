#!/usr/bin/env ruby

require 'rubygems'
require 'tmail'
require 'appscript'
include Appscript

of = app('OmniFocus')
message = STDIN.read
mail = TMail::Mail.parse(message)
tasks = of.documents[1].get
tasks.make(
           :new => :inbox_task, 
           :with_properties =>
             {:name => mail.subject, :note => mail.body}
           )
