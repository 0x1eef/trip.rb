##
# Sort methods in ascending order based
# on the line number where a method is
# defined.
def sort_listing(listing)
  listing.sort_by { _1.files[1] }
end
