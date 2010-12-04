#!/usr/bin/ruby 
require 'tk'
require 'fileutils'
require 'quickanddirty'

#---------------------------------------------------------------------
# CLASSES
#---------------------------------------------------------------------

class Ring

  def initialize(vals, init)
    @vals = vals
    @index = @vals.index(init) 
  end

  def next
    @index =  (@index + 1) % @vals.size
    @vals[@index]
  end

  def current
    @vals[@index]
  end

  def to_s
    @vals[@index].to_s
  end
end

#represents each entry in our world...
class Entry
  
  STATES = [ "OPEN", "WORKING", "CLOSED" ]

  attr_reader :data
  attr_accessor :button

  def initialize(line)
    state, @data = line.chomp.split("#")
    @state = Ring.new(STATES, state)
  end

  def toggle_state
    @state.next
  end

  def state
    @state.to_s
  end

  def to_s
    "#{@state}##{@data}"
  end

  def self.load_entries(filename)
    entries = [ ]
    if File.exist?(filename)
      File.open(filename,"r") do |f|
        f.each_line { |l| entries << Entry.new(l) }
      end
    end
    entries
  end

  def self.save_entries(filename, entries)
    File.open(filename,"w") do |f|
      entries.each { |e| f.puts e.to_s }
    end
  end

end

#------------------------------------------------------------
# HELPER METHODS
#------------------------------------------------------------

def add_entry_button(frame, entry)
  button = TkButton.new(frame) { 
    text entry.data 
    background COLORS[ 'background.' + entry.state]
    foreground COLORS[ 'foreground.' + entry.state]
    anchor "w"
    command proc {
      entry.toggle_state
      button.background COLORS['background.' + entry.state]
      button.foreground COLORS['foreground.' + entry.state]
      $STATUS.text = create_entries_status
    }
  }
  button.pack("side" => "top", "fill" => "x" )
  entry.button = button
end

def remove_closed_entries
  $ENTRIES.each { |entry| entry.button.unpack if entry.state == "CLOSED" }
  $ENTRIES.delete_if { |entry| entry.state == "CLOSED" }
  $STATUS.text create_entries_status
end

def create_entries_status
  done = 0
  $ENTRIES.each { |e| done += 1 if e.state == "CLOSED" }
  "#{done} / #{$ENTRIES.size}"
end

#------------------------------------------------------------
# MAIN PROGRAM
#------------------------------------------------------------

opts, args = QandD.parse_options("f",ARGV)

# my constants
WORK_DIR=ENV['HOME'] + '/.todo.d' 
Dir.mkdir(WORK_DIR) unless File.directory?(WORK_DIR)
LOCK_FILE = WORK_DIR + "/lock"
DATA_FILE=WORK_DIR + '/todo.data' 
COLORS = { "background.OPEN" => "gray80", "foreground.OPEN" => "black", 
           "background.WORKING" => "gray70", "foreground.WORKING" => "white",
           "background.CLOSED" => "gray30", "foreground.CLOSED" => "white" }
    
File.exist?(LOCK_FILE) and (! opts["f"]) and abort("an instance is already running.")
FileUtils.touch(LOCK_FILE)

# loads configuration file
CONFIG_FILE = WORK_DIR + '/todo.cfg'
load CONFIG_FILE if File.exist?(CONFIG_FILE)
BUTTONS_PER_FRAME = 100

# load the data
$ENTRIES = File.exist?(DATA_FILE) ? Entry.load_entries(DATA_FILE) : [ ]

# frames
root = TkRoot.new() { title "todo list" }
newentry_frame = TkFrame.new(root).pack( "side" => "top", "fill" => "x" )
status_bar = TkFrame.new(root).pack( "side" => "bottom", "fill" => "x" )
entries_frames = [ ]
entries_frames << TkFrame.new(root).pack( 'fill' => 'both' )
#1.times { entries_frames << TkFrame.new(root).pack( "side" => "left", "fill" => "both" )  }

# create status bar
$STATUS = TkLabel.new(status_bar) { text create_entries_status }
$STATUS.pack( "side" => "right" )


# entering new data component...

label = TkLabel.new(newentry_frame) { text "new task:" }
label.pack( "side" => "left" )
inputfield = TkEntry.new(newentry_frame) {
  width 48
  
}
inputfield.pack( "side" => "left", "fill" => "x" )
button = TkButton.new(newentry_frame) {
  text "add"
  command proc {
    entry = Entry.new("OPEN##{inputfield.get}")
    $ENTRIES << entry
    # frame = entries_frames [ $ENTRIES.size / BUTTONS_PER_FRAME ]
    frame = entries_frames[0]
    add_entry_button(frame, entry)
    inputfield.delete(0, inputfield.get.length)
    $STATUS.text = create_entries_status
  }
}
button.pack("side" => "left")
flush_button = TkButton.new(newentry_frame) { 
  text "flush" 
  command proc {
    remove_closed_entries
    $STATUS.text = create_entries_status
  }
}
flush_button.pack("side" => "left")

exit_button = TkButton.new(newentry_frame) { 
    text "exit" 
    command proc {
      Kernel.exit
    }
}
exit_button.pack("side" => "right")

# entries list...
$ENTRIES.each_index do |idx|
    #frame = entries_frames[ idx / BUTTONS_PER_FRAME ]
    frame = entries_frames[0]
    add_entry_button( frame, $ENTRIES[idx] )
end

at_exit do
   Entry.save_entries(DATA_FILE, $ENTRIES) 
   File.delete(LOCK_FILE)
end

Tk.mainloop()
