# Helper method to read Gymfile configurations and return as a hash
def read_gymfile(filepath = "Gymfile")
  unless File.exist?(filepath)
    FastlaneCore::UI.user_error!("Gymfile not found at path: #{filepath}")
  end
  FastlaneCore::UI.message("Gymfile found at path: #{filepath}")

  config = {}

  File.readlines(filepath).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#") # Skip empty lines and comments

    if line.include?("(") && line.include?(")")
      key = line.split("(").first
      value = line.split('"')[1] # Assumes the value is within double quotes
      config[key] = value
    end
  end

  config
end
