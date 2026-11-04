# Metrics for Rails requests, Active Job and Puma, exported to Prometheus by the yabeda_prometheus Puma plugin
# (config/puma.rb).

# Job metrics need their own hook into Active Job
Yabeda::ActiveJob.install!

# Solid Queue runs its workers as processes forked from Puma, and the default in-memory store would keep their
# job metrics out of the exporter's reach. Every process writes to files here instead; Puma clears the directory
# at boot. Tests keep the in-memory store.
unless Rails.env.test?
  dir = Rails.root.join("tmp/prometheus")
  FileUtils.mkdir_p(dir)
  Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: dir.to_s)
end
