##如题：
##注意：清掉了默认的菜单里的队伍状态相关内容
#==============================================================================
# ** Scene_Menu  修改by：洮羱芝闇
#------------------------------------------------------------------------------
#  This class performs menu screen processing.
#==============================================================================

class Scene_Menu
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     menu_index : command cursor's initial position
  #--------------------------------------------------------------------------
  def initialize(menu_index = 0)
    @menu_index = menu_index
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def main
    # Make command window
    s1 = $data_system.words.item
    s2 = $data_system.words.skill
    s3 = $data_system.words.equip
    s4 = "Status"
    s5 = "保存"
    s6 = "退出"
    @command_window = Window_Command.new(160, [s1,  s5, s6])
    @command_window.index = @menu_index
    # If number of party members is 0
    if $game_party.actors.size == 0
      # Disable items, skills, equipment, and status
      @command_window.disable_item(0)

    end
    # If save is forbidden
    if $game_system.save_disabled
      # Disable save
      @command_window.disable_item(4)
    end

    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of windows
    @command_window.dispose

  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Update windows
    @command_window.update

    # If command window is active: call update_command
    if @command_window.active
      update_command
      return
    end
    # If status window is active: call update_status
    if @status_window.active
      update_status
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when command window is active)
  #--------------------------------------------------------------------------
  def update_command
    # If B button was pressed
    if Input.trigger?(Input::B)
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Switch to map screen
      $scene = Scene_Map.new
      return
    end
    # If C button was pressed
    if Input.trigger?(Input::C)
      # If command other than save or end game, and party members = 0
      if $game_party.actors.size == 0 and @command_window.index < 4
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Branch by command window cursor position
      case @command_window.index
      when 0  # item
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to item screen
        $scene = Scene_Item.new
      when 1# save
        # If saving is forbidden
        if $game_system.save_disabled
          # Play buzzer SE
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to save screen
        $scene = Scene_Save.new
      when 2  # end game
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to end game screen
        $scene = Scene_End.new
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when status window is active)
  #--------------------------------------------------------------------------
  def update_status
    # If B button was pressed
    if Input.trigger?(Input::B)
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Make command window active
      @command_window.active = true
      @status_window.active = false
      @status_window.index = -1
      return
    end
    # If C button was pressed
    if Input.trigger?(Input::C)
      # Branch by command window cursor position
      case @command_window.index
      when 1  # skill
        # If this actor's action limit is 2 or more
        if $game_party.actors[@status_window.index].restriction >= 2
          # Play buzzer SE
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to skill screen
        $scene = Scene_Skill.new(@status_window.index)
      when 2  # equipment
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to equipment screen
        $scene = Scene_Equip.new(@status_window.index)
      when 3  # status
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to status screen
        $scene = Scene_Status.new(@status_window.index)
      end
      return
    end
  end
end

class Scene_Save < Scene_File
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super("Which file would you like to save to?")
  end
  #--------------------------------------------------------------------------
  # * Decision Processing
  #--------------------------------------------------------------------------
  def on_decision(filename)
    # Play save SE
    $game_system.se_play($data_system.save_se)
    # Write save data
    file = File.open(filename, "wb")
    write_save_data(file)
    file.close
    # If called from event
    if $game_temp.save_calling
      # Clear save call flag
      $game_temp.save_calling = false
      # Switch to map screen
      $scene = Scene_Map.new
      return
    end
    # Switch to menu screen
    $scene = Scene_Menu.new(1)
  end
  #--------------------------------------------------------------------------
  # * Cancel Processing
  #--------------------------------------------------------------------------
  def on_cancel
    # Play cancel SE
    $game_system.se_play($data_system.cancel_se)
    # If called from event
    if $game_temp.save_calling
      # Clear save call flag
      $game_temp.save_calling = false
      # Switch to map screen
      $scene = Scene_Map.new
      return
    end
    # Switch to menu screen
    $scene = Scene_Menu.new(1)
  end
  #--------------------------------------------------------------------------
  # * Write Save Data
  #     file : write file object (opened)
  #--------------------------------------------------------------------------
  def write_save_data(file)
    # Make character data for drawing save file
    characters = []
    for i in 0...$game_party.actors.size
      actor = $game_party.actors[i]
      characters.push([actor.character_name, actor.character_hue])
    end
    # Write character data for drawing save file
    Marshal.dump(characters, file)
    # Wrire frame count for measuring play time
    Marshal.dump(Graphics.frame_count, file)
    # Increase save count by 1
    $game_system.save_count += 1
    # Save magic number
    # (A random value will be written each time saving with editor)
    $game_system.magic_number = $data_system.magic_number
    # Write each type of game object
    Marshal.dump($game_system, file)
    Marshal.dump($game_switches, file)
    Marshal.dump($game_variables, file)
    Marshal.dump($game_self_switches, file)
    Marshal.dump($game_screen, file)
    Marshal.dump($game_actors, file)
    Marshal.dump($game_party, file)
    Marshal.dump($game_troop, file)
    Marshal.dump($game_map, file)
    Marshal.dump($game_player, file)
  end
end
class Scene_End
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def main
    # Make command window
    s1 = "To Title"
    s2 = "Shutdown"
    s3 = "Cancel"
    @command_window = Window_Command.new(192, [s1, s2, s3])
    @command_window.x = 320 - @command_window.width / 2
    @command_window.y = 240 - @command_window.height / 2
    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame Update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of window
    @command_window.dispose
    # If switching to title screen
    if $scene.is_a?(Scene_Title)
      # Fade out screen
      Graphics.transition
      Graphics.freeze
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Update command window
    @command_window.update
    # If B button was pressed
    if Input.trigger?(Input::B)
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Switch to menu screen
      $scene = Scene_Menu.new(2)
      return
    end
    # If C button was pressed
    if Input.trigger?(Input::C)
      # Branch by command window cursor position
      case @command_window.index
      when 0  # to title
        command_to_title
      when 1  # shutdown
        command_shutdown
      when 2  # quit
        command_cancel
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Process When Choosing [To Title] Command
  #--------------------------------------------------------------------------
  def command_to_title
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Fade out BGM, BGS, and ME
    Audio.bgm_fade(800)
    Audio.bgs_fade(800)
    Audio.me_fade(800)
    # Switch to title screen
    $scene = Scene_Title.new
  end
  #--------------------------------------------------------------------------
  # * Process When Choosing [Shutdown] Command
  #--------------------------------------------------------------------------
  def command_shutdown
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Fade out BGM, BGS, and ME
    Audio.bgm_fade(800)
    Audio.bgs_fade(800)
    Audio.me_fade(800)
    # Shutdown
    $scene = nil
  end
  #--------------------------------------------------------------------------
  # *  Process When Choosing [Cancel] Command
  #--------------------------------------------------------------------------
  def command_cancel
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Switch to menu screen
    $scene = Scene_Menu.new(2)
  end
end