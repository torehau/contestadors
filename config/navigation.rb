# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'your_selected_class'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  navigation.active_leaf_class = ''

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>:if => Proc.new { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>:unless => Proc.new { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>. 
    #
    if include_tournaments_menu_item
      primary.item :home, 'Tournaments', tournaments_path, :highlights_on => lambda { current_controller_new 'tournaments' }
    end
    primary.item :rules, 'Rules', predictions_rules_path(current_tournament.permalink), :highlights_on => lambda { current_controller_new 'rules' }
    primary.item :predictions, 'Predictions', prediction_menu_link, :highlights_on => lambda { current_controller_new 'predictions' }
    selected = selected_contest

    if before_contest_participation_ends
      primary.item :invitations, 'Invitations', pending_invitations_path(current_tournament.permalink), :highlights_on => lambda { current_controller_new 'invitations' and current_action_new ['pending', 'accepted'] }
    #primary.item :contests, 'Contests', contests_path("championship", "all"), :highlights_on => lambda { current_context?({'contests' => ['index']}, {'contests' => ['new', 'create']}) }
      primary.item :contests, 'Contests', contests_main_menu_link, :highlights_on => lambda { matches_current_context([HighlightCondition.new('contests', 'index')], [HighlightCondition.new('contests', 'new'), HighlightCondition.new('contests', 'create')]) }

      if selected and selected.contest.id == current_tournament.id
        primary.item :contest_instance, selected.name, contest_instance_menu_link(selected),
            :highlights_on => lambda { matches_current_context([HighlightCondition.new("score_tables"), HighlightCondition.new("participants"), HighlightCondition.new("contests", "show"), HighlightCondition.new("contests", "upcoming_events"), HighlightCondition.new("contests", "latest_results"), HighlightCondition.new("invitations", "index", "admin")], [HighlightCondition.new("contests", "edit"), HighlightCondition.new("contests", "update"), HighlightCondition.new("invitations", "new"), HighlightCondition.new("invitations", "copy")])}
      #current_controller_or_context?(["score_tables", "participants"], {"contests" => ["show", "upcoming_events", "latest_results"]}, {"contests" => ["edit", "update"], "invitations" => ["new"]})}
      end
    else
      contest_instances = current_user.instances_of(@contest, :all)
      contest_count = contest_instances.count

      if contest_count > 3
        primary.item :contests, 'Contests', contests_main_menu_link, :highlights_on => lambda { matches_current_context([HighlightCondition.new('contests', 'index')], [HighlightCondition.new('contests', 'new'), HighlightCondition.new('contests', 'create')]) }
        primary.item :contest_instance, selected.name, contest_instance_menu_link(selected),
            :highlights_on => lambda { matches_current_context([HighlightCondition.new("score_tables"), HighlightCondition.new("participants"), HighlightCondition.new("contests", "show"), HighlightCondition.new("contests", "upcoming_events"), HighlightCondition.new("contests", "latest_results"), HighlightCondition.new("invitations", "index", "admin")], [HighlightCondition.new("contests", "edit"), HighlightCondition.new("contests", "update"), HighlightCondition.new("invitations", "new"), HighlightCondition.new("invitations", "copy")])}
      elsif contest_count > 0
        contest_instances.each do |ci|
          primary.item :contest_instance, ci.name, contest_instance_menu_link(ci),
              :highlights_on => lambda { ci.id == selected.id and matches_current_context([HighlightCondition.new("score_tables"), HighlightCondition.new("participants"), HighlightCondition.new("contests", "show"), HighlightCondition.new("contests", "upcoming_events"), HighlightCondition.new("contests", "latest_results"), HighlightCondition.new("invitations", "index", "admin")], [HighlightCondition.new("contests", "edit"), HighlightCondition.new("contests", "update"), HighlightCondition.new("invitations", "new"), HighlightCondition.new("invitations", "copy")])}
        end
      end
    end

    # Add an item which has a sub navigation (same params, but with block)
    #primary.item :key_2, 'name', url, options do |sub_nav|
    #  # Add an item to the sub navigation (same params again)
    #  sub_nav.item :key_2_1, 'name', url, options
    #end
    #
    ## You can also specify a condition-proc that needs to be fullfilled to display an item.
    ## Conditions are part of the options. They are evaluated in the context of the views,
    ## thus you can use all the methods and vars you have available in the views.
    #primary.item :key_3, 'Admin', url, :class => 'special', :if => Proc.new { current_user.admin? }
    #primary.item :key_4, 'Account', url, :unless => Proc.new { logged_in? }

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    # primary.dom_id = 'menu-id'
    # primary.dom_class = 'menu-class'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false

  end

end
