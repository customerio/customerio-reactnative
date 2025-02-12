const Env = {
  buildTimestamp: Math.floor(Date.now() / 1000),
  cdpApiKey: 'CDP_API_KEY',
  siteId: 'SITE_ID',
  workspaceName: 'WORKSPACE_NAME',
  branchName: 'BRANCH_NAME',
  commitHash: 'COMMIT_HASH',
  commitsAheadCount: 'COMMITS_AHEAD_COUNT',
};

export default Env;
