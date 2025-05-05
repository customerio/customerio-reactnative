# Parse JSON out of GitHub Context JSON when being executed on GitHub Actions.
class GitHub
  # payload for releases: https://docs.github.com/en/webhooks-and-events/webhooks/webhook-events-and-payloads?actionType=published#release
  # payload for pull requests: https://docs.github.com/en/webhooks-and-events/webhooks/webhook-events-and-payloads?actionType=synchronize#pull_request

  def initialize()
    github_actions_metadata_path = ENV["GITHUB_EVENT_PATH"] # the path to the JSON file is the value of this environment variable.
    # Read the GitHub provided JSON file > Parse the JSON into a Ruby Hash > Construct a GitHub class instance to easily pull out metadata for the notes.
    @github_context = JSON.parse(File.open(github_actions_metadata_path).read)
  end

  def is_commit_pushed
    @github_context["head_commit"] != nil
  end

  def is_pull_request
    @github_context["pull_request"] != nil
  end

  # Functions below only meant for when a github actions event is a push event

  def push_branch
    # the branch name is: "refs/heads/<name-here>". We use gsub to string replace and remove "refs/heads/" part to only get the branch name
    return @github_context["ref"].gsub!('refs/heads/', '')
  end

  def push_commit_hash
    return @github_context["head_commit"]["id"]
  end

  # Functions below only meant for when a github actions event is a pull request

  def pr_author
    return @github_context["pull_request"]["user"]["login"]
  end

  def pr_commit_hash
    # Unfortunately, the git commit hash isn't included in the GitHub Actions metadata JSON for a release. We have to get that value manually.
    return @github_context["pull_request"]["head"]["sha"][0..8]
  end

  def pr_commits
    return @github_context["pull_request"]["commits"]
  end

  def pr_title
    @github_context["pull_request"]["title"]
  end

  def pr_number
    @github_context["pull_request"]["number"]
  end

  def pr_source_branch
    return @github_context["pull_request"]["head"]["ref"]
  end

  def pr_destination_branch
    return @github_context["pull_request"]["base"]["ref"]
  end
end
