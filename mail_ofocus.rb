#!/usr/bin/env ruby

require 'rubygems'
require 'mail'
require 'appscript'; include Appscript
require 'iconv'

message = STDIN.read
mail = Mail.new(message)

notes = ""

if mail.multipart? then
  #puts "multipart mail"
  # mail.parts.map do |m|
  #   notes << m.content_type << "\n"
  # end

  mail.parts.map do |p|
    if p.content_type =~ /text\/plain/
      # puts "plain text portion"
      notes << p.body.decoded << "\n"
      notes << "------------------------\n"
    elsif p.content_type =~ /multipart\/alternative/
      #puts  "multipart-alternative\n"
      nest = Mail.new(p)
      nest.parts.map do |n|
        if n.content_type =~ /text\/plain/
          notes << n.body.decoded << "\n"
        else
          notes << "[non-text attachment]\n"
        end
      end
      # end of processing multipart/alternative
    else
      notes << "[non-text attachment]\n"
    end
  end
else
	notes << mail.body.decoded
end

#puts notes

notes.force_encoding('UTF-8')
# this forces the transliteration of a number of characters.  if i were
# really thinking here, i'd iterate through the from charsets more
# flexibly.
unote = Iconv.conv("UTF-8//IGNORE//TRANSLIT", "CP1252", notes)

of = app('OmniFocus')
# tasks = of.documents[1].get
tasks = of.default_document
tasks.make( :new => :inbox_task,
            :with_properties => {:name => mail.subject, :note => unote} )
