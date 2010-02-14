#!/usr/bin/env ruby

require 'rubygems'
require 'tmail'
require 'appscript'
include Appscript

of = app('OmniFocus')
message = STDIN.read
mail = TMail::Mail.parse(message)

notes = ""

if mail.multipart? then
  mail.parts.each do |m|
    if m.content_type == "text/plain"
      notes << m.body << "\n"
      # notes << "------------------------\n"
    elsif m.content_type == "multipart/alternative"
      m.parts.each do |nested|
    		if nested.content_type == "text/plain"
          notes << nested.body << "\n"
        end
      end
    else
      notes << "[non-text attachment]\n"
    end
  end
else 
	notes = mail.body
end

#puts notes

tasks = of.documents[1].get
tasks.make(:new => :inbox_task, 
           :with_properties => {:name => mail.subject, :note => notes}
           )
