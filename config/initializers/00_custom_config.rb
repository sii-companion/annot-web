CONFIG = YAML.load_file("#{Rails.root.to_s}/config/companion.yml")[Rails.env]

if not File.exist?("#{CONFIG['nextflowpath']}/nextflow") then
  raise "Nextflow engine not available in #{Rails.env}! Check config file at #{Rails.root.to_s}/config/companion.yml"
end

if not File.exist?("#{CONFIG['locationconfig']}") then
  raise "Missing location configuration for #{Rails.env}! Check config file at #{Rails.root.to_s}/config/companion.yml"
end

if not File.exist?("#{CONFIG['nextflowscript']}") then
  raise "Missing nextflow script for #{Rails.env}! Check config file at #{Rails.root.to_s}/config/companion.yml"
end

if not system("gt -version") then
  raise "gt binary not found in PATH! Please install and/or set the correct path to find it."
end