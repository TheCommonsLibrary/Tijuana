# on the recurring donor upgrade form the labels
# occlude the button & poltergeist doesn't like it.
# with selenium you can just `choose "+$5"`

def choose_via_id(id)
  find(id).trigger('click')
end
