module Byebug

  # Mix-in module to assist in command parsing.
  module SteppingFunctions
    def parse_stepping_args(command_name, match)
      if match[1].nil?
        force = Setting[:forcestep]
      elsif match[1] == '+'
        force = true
      elsif match[1] == '-'
        force = false
      end
      steps = get_int(match[2], command_name, 1)
      return [steps, force]
    end
  end

  # Implements byebug "next" command.
  class NextCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* n(?:ext)?([+-])? (?:\s+(\S+))? \s*$/x
    end

    def dlog(msg)
      File.open("meta.log", 'a') { |file|
        file.puts(msg)
      }
    end

    def execute
      steps, force = parse_stepping_args("Next", @match)
      return unless steps

      dlog("ME #{$$}: Here we are in next.")
      dlog("ME #{$$}: FORK TIME")
      $previous_pid ||= []

      parent_pid = $$
      pid = fork
      if pid
        dlog("PARENT #{$$}: saving child pid #{pid}")
        $previous_pid.push pid
        @state.context.step_over steps, @state.frame_pos, force
        @state.proceed
      else
        dlog("CHILD #{$$}: suspending")
        #  Process.setpgrp
        #  Process.setsid
        Process.kill 19, $$
        dlog("CHILD #{$$}: resumed!")
      end

    end

    class << self
      def names
        %w(next)
      end

      def description
        %{n[ext][+-]?[ nnn]\tstep over once or nnn times,
          \t\t'+' forces to move to another line.
          \t\t'-' is the opposite of '+' and disables the :forcestep setting.
         }
      end
    end
  end



  # Implements byebug "previous" command.
  class PreviousCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* prev(?:ious)?$/x
    end

    def dlog(msg)
      File.open("meta.log", 'a') { |file|
        file.puts(msg)
      }
    end

    def execute
      dlog("ME #{$$}: Thinking about time travel...");
      if $previous_pid && ! $previous_pid.empty?
        previous_pid = $previous_pid.pop
        dlog("ME #{$$}: I found a previous pid #{previous_pid}! TIME TRAVEL TIME")
        Process.kill 18, previous_pid
        dlog("ME #{$$}: If you meet your previous self, kill yourself.")
        Process.waitall
        Kernel.exit!
        #  Process.kill 9, $$
      end
      dlog("ME #{$$}: I was unable to time travel. Maybe it is a myth.");
    end

    class << self
      def names
        %w(next)
      end

      def description
        %{n[ext][+-]?[ nnn]\tstep over once or nnn times,
          \t\t'+' forces to move to another line.
          \t\t'-' is the opposite of '+' and disables the :forcestep setting.
         }
      end
    end
  end

  # Implements byebug "step" command.
  class StepCommand < Command
    self.allow_in_post_mortem = false

    def regexp
      /^\s* s(?:tep)?([+-]) ?(?:\s+(\S+))? \s*$/x
    end

    def execute
      steps, force = parse_stepping_args("Step", @match)
      return unless steps
      @state.context.step_into steps, force
      @state.proceed
    end

    class << self
      def names
        %w(step)
      end

      def description
        %{
          s[tep][+-]?[ nnn]\tstep (into methods) once or nnn times
          \t\t'+' forces to move to another line.
          \t\t'-' is the opposite of '+' and disables the :forcestep setting.
         }
      end
    end
  end
end
