
=begin
    'Nyle'
      minimal graphics framework using Ruby/GTK3 and rcairo

      Copyright (c) 2018 Koki Kitamura
      Released under the MIT license
      https://opensource.org/licenses/mit-license.php
=end

module Nyle
  class Error < StandardError; end

  # Screen
  class Screen < Gtk::DrawingArea
    attr_reader :width, :height, :status
    def initialize(width = DEFAULT_WIDTH, height = DEFAULT_HEIGHT, bgcolor: :WHITE, trace: false)
      super()
      @width         = width
      @height        = height
      @trace         = trace
      @bgcolor       = bgcolor
      @running_count = 0
      @status        = nil

      @fill_done     = false

      Nyle.module_eval {
        _set_screen_size(width, height)
      }

      # Draw to 'CairoContext' of ImageSurface once, and copy to 'CairoContext' of DrawingArea
      @canvas = Cairo::ImageSurface.new(@width, @height)

      self.signal_connect(:configure_event) do |widget, event|
        ;   # For resizing and so on
      end

      self.signal_connect(:draw) do |widget, cairo_context|
        Nyle.module_eval {
          _update_mouse_state
          _update_key_state
        }
        # Draw to 'CairoContext' of ImageSurface
        Cairo::Context.new(@canvas) do |cr|
          Nyle.module_eval {
            _set_cr(cr)
          }
          unless @trace                       # If not trace, fill screen each time
            Nyle.cr.set_source_color(@bgcolor)
            Nyle.cr.paint
          else
            unless @fill_done
              Nyle.cr.set_source_color(@bgcolor)  # fill once
              Nyle.cr.paint
              @fill_done = true
            end
          end
          update
          draw
        end
        # Copy to 'CairoContext' of DrawingArea
        Nyle.module_eval {
          _set_cr(cairo_context)
        }
        pattern = Cairo::SurfacePattern.new(@canvas)
        Nyle.cr.set_source(pattern)
        Nyle.cr.paint
        @running_count += 1
      end

      # Need not only :pointer_motion but also :button_press and :button_release
      self.add_events([:button_press_mask,
                       :button_release_mask,
                       :pointer_motion_mask])

      # Signal handler for mouse position
      self.signal_connect(:motion_notify_event) do |widget, event|
        Nyle.module_eval {
          _set_mouse_pos(event.x.to_i, event.y.to_i)
        }
        false
      end
    end

    # When single screen, create frame to show self
    def show_all(title = DEFAULT_TITLE)
      f = Nyle::Frame.new(@width, @height, {title: title})
      f.set_current(self)
      f.show_all
      f
    end

    # Abstract methods to be overriden
    private def update  ; end
    private def draw    ; end
    private def suspend ; end
    private def resume  ; end
  end

end

