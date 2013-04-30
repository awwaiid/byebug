require_relative 'test_helper'

describe 'Frame Command' do
  include TestDsl

  def after_setup
    Byebug::Command.settings[:width] =
      "--> #0  A.d(e#String) at #{fullpath('frame')}:16".size
  end

  it 'must go up' do
    enter 'break 16', 'cont', 'up'
    debug_file('frame') { state.line.must_equal 12 }
  end

  it 'must go up by specific number of frames' do
    enter 'break 16', 'cont', 'up 2'
    debug_file('frame') { state.line.must_equal 8 }
  end

  it 'must go down' do
    enter 'break 16', 'cont', 'up', 'down'
    debug_file('frame') { state.line.must_equal 16 }
  end

  it 'must go down by specific number of frames' do
    enter 'break 16', 'cont', 'up 3', 'down 2'
    debug_file('frame') { state.line.must_equal 12 }
  end

  it 'must set frame' do
    enter 'break 16', 'cont', 'frame 2'
    debug_file('frame') { state.line.must_equal 8 }
  end

  it 'must set frame to the first one by default' do
    enter 'break 16', 'cont', 'up', 'frame'
    debug_file('frame') { state.line.must_equal 16 }
  end

  it 'must print current stack frame when without arguments' do
    enter 'break A.d', 'cont', 'up', 'frame'
    debug_file('frame') { check_output_includes "#0  A.d(e#String) at #{fullpath('frame')}:15" }
  end

  it 'must set frame to the first one' do
    enter 'break 16', 'cont', 'up', 'frame 0'
    debug_file('frame') { state.line.must_equal 16 }
  end

  it 'must set frame to the last one' do
    enter 'break 16', 'cont', 'frame -1'
    debug_file('frame') { state.file.must_match /test_dsl.rb/ }
    check_output_doesnt_include "at #{fullpath('frame')}:"
  end

  it 'must not set frame if the frame number is too low' do
    enter 'break 16', 'cont', 'down'
    debug_file('frame') { state.line.must_equal 16 }
    check_output_includes \
      'Adjusting would put us beyond the newest (innermost) frame.',
      interface.error_queue
  end

  it 'must not set frame if the frame number is too high' do
    enter 'break 16', 'cont', 'up 100'
    debug_file('frame') { state.line.must_equal 16 }
    check_output_includes \
      'Adjusting would put us beyond the oldest (initial) frame.',
      interface.error_queue
  end

  describe 'full path settings' do
    def short_path(fullpath)
      separator = File::ALT_SEPARATOR || File::SEPARATOR
      "...#{separator}" + fullpath.split(separator)[-3..-1].join(separator)
    end

    before do
      Byebug::Command.settings[:callstyle] = :last
    end

    it 'must display current backtrace with full path = true' do
      enter 'set fullpath', 'break 16', 'cont', 'where'
      debug_file 'frame'
      check_output_includes "--> #0  A.d(e#String) at #{fullpath('frame')}:16",
                            "    #1  A.c at #{fullpath('frame')}:12"
    end

    it 'must display current backtrace with full path = false' do
      enter 'set nofullpath', 'break 16', 'cont', 'where'
      debug_file 'frame'
      check_output_includes \
        "--> #0  A.d(e#String) at #{short_path(fullpath('frame'))}:16",
        "    #1  A.c at #{short_path(fullpath('frame'))}:12"
    end
  end

  describe 'callstyles' do
    it 'displays current backtrace with callstyle "last"' do
      enter 'set callstyle last', 'break 16', 'cont', 'where'
      debug_file 'frame'
      check_output_includes "--> #0  A.d(e#String) at #{fullpath('frame')}:16",
                            "    #1  A.c at #{fullpath('frame')}:12"          ,
                            "    #2  A.b at #{fullpath('frame')}:8"           ,
                            "    #3  A.a at #{fullpath('frame')}:5"
    end

    it 'displays current backtrace with callstyle "short"' do
      enter 'set callstyle short', 'break 16', 'cont', 'where'
      debug_file 'frame'
      check_output_includes "--> #0  d(e) at #{fullpath('frame')}:16",
                            "    #1  c at #{fullpath('frame')}:12"   ,
                            "    #2  b at #{fullpath('frame')}:8"    ,
                            "    #3  a at #{fullpath('frame')}:5"
    end

    it 'displays current backtrace with callstyle "tracked"' do
      skip('XXX: Style supported but not working....')
      enter 'set callstyle tracked'
      debug_file 'frame'
      check_output_includes \
        'Invalid call style tracked. Should be one of: "last".'
      Byebug::Command.settings[:callstyle].must_equal :last
    end
  end

  it 'must change to frame in another thread' do
    skip('No threads supported')
  end

  it 'must not change to frame in another thread if thread doesn\'t exist' do
    skip('No threads supported')
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      #skip 'TODO: This test fails with \'Segmentation fault\'.'
      enter 'cont', 'frame'
      debug_file('post_mortem') { state.line.must_equal 8 }
    end
  end

end
