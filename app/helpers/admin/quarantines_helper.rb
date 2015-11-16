module Admin::QuarantinesHelper
  def link_to_quarantined_sequence(sequence)
    link_to [sequence.campaign.name, sequence.name].join(' ⇒ '), edit_admin_page_sequence_path(sequence)
  end
end
