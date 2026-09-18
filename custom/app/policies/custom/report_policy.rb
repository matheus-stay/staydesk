# Entra em ReportPolicy pelo gancho prepend_mod_with: relatórios deixam de ser só
# do administrador quando o papel do agente concede (SPEC-12).
module Custom::ReportPolicy
  def view?
    return true if super

    @account_user.staydesk_permissions.intersect?(%w[report_manage staydesk_report_own])
  end
end
