require 'rexml/document'
require 'rexml/element'
require 'base64'

class Item
  attr_accessor :data

  def initialize(data)
    @data = data
  end

  def to_xml
    item = REXML::Element.new('item')
    item.add_attribute('arg', data[:title])
    item.add_attribute('uid', Base64.encode64(data[:title]).strip)
    item.add_element('title').text = data[:title]
    item.add_element('subtitle').text = data[:subtitle] || "Enter to copy"
    item
  end
end

class Document
  attr_accessor :nodes

  def initialize(nodes)
    @nodes = nodes
  end

  def to_xml
    document = REXML::Document.new('<?xml version="1.0"?>')
    items = document.add_element('items')
    nodes.each do |node|
      items << node.to_xml
    end
    document.to_s
  end
end

class App
  attr_accessor :clipboard, :find_and_replace

  def initialize(subject: `pbpaste`, matcher: ARGV[0] || '')
    self.clipboard = subject
    self.find_and_replace = (matcher.match(/s\/([^\/]*)\/([^\/]*)(?:\/([a-z]+))?/)).to_a
  end

  def flags
    find_and_replace[3] || ''
  end

  def global?
    flags.match(/g/)
  end

  def flags?
    flags.length > 0
  end

  def find
    Regexp.new(find_and_replace[1].to_s, flags)
  end

  def replace
    find_and_replace[2].to_s
  end

  def valid?
    find.to_s.length > 0
  end

  def run
    if valid?
      [Item.new(title: clipboard.send(global? ? :gsub : :sub, find, replace))]
    else
      [Item.new({title: 'Invalid Format', subtitle: 's/find/replace/flags'})]
    end
  end

end

puts Document.new(App.new.run).to_xml
