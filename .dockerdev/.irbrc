# Loaded through IRBRC only inside the dev containers: keeps console history in the `history` volume
IRB.conf[:HISTORY_FILE] = ENV["IRB_HISTFILE"] if ENV["IRB_HISTFILE"]
