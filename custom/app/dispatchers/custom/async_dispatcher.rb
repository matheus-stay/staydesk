# Entra em AsyncDispatcher pelo gancho prepend_mod_with('AsyncDispatcher').
module Custom::AsyncDispatcher
  def listeners
    super + [Staydesk::SlaListener.instance, Staydesk::SlaAutomationListener.instance]
  end
end
