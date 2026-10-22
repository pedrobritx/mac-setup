# Catalogue source checks

Checked on 21 October 2026. Runtime availability still belongs to the vendor;
this record is catalogue evidence, not proof of installation or account access.

- Package tokens and application bundle names: [Homebrew JSON API](https://formulae.brew.sh/docs/api/).
  Additions were queried through `/api/cask/<token>.json` and
  `/api/formula/<token>.json`, including disabled/deprecated status.
- [Codex is a cask](https://formulae.brew.sh/cask/codex), not the old formula.
- [Gemini CLI's formula is deprecated](https://formulae.brew.sh/formula/gemini-cli);
  the guided entry uses [Google's official installer](https://github.com/google-gemini/gemini-cli#installation).
- App IDs/names: [Apple lookup API](https://itunes.apple.com/lookup?id=361309726,361304891,361285480,571213070,424390742,634148309,424389933,434290957,1444636541,899247664,1496833156,897118787,640199958,497799835,310633997,803453959,823766827,1475387142,1176074088,897446215,1333542190,1113153706&country=br).
  Pages, Numbers and Keynote use the supplied universal listings; older standalone
  Mac IDs no longer appeared in the lookup response. Mac support was also checked
  on the [Pages listing](https://apps.apple.com/br/app/id361309726?platform=mac),
  [Canva listing](https://apps.apple.com/br/app/id897446215?platform=mac) and
  [Photomator listing](https://apps.apple.com/us/app/id1444636541?platform=mac).
- 1Password: the App Store response identifies `1333542190` as 1Password 7.
  [The current cask](https://formulae.brew.sh/cask/1password) installs the current
  desktop app, so it remains the declared source.
- App Store installation semantics and prior ownership:
  [official mas documentation](https://github.com/mas-cli/mas).
- [Figma MCP](https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/),
  [GitHub MCP](https://github.com/github/github-mcp-server),
  [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/),
  [Notion MCP](https://developers.notion.com/guides/mcp/overview),
  [Vercel MCP](https://vercel.com/docs/agent-resources/vercel-mcp),
  [Supabase MCP](https://supabase.com/docs/guides/ai-tools/mcp),
  [Railway MCP](https://docs.railway.com/ai/mcp-server),
  [Stripe MCP](https://docs.stripe.com/mcp),
  [Slack MCP](https://docs.slack.dev/ai/slack-mcp-server/),
  [Canva Dev MCP](https://www.canva.dev/docs/apps/dev-mcp-server/). Canva's
  developer server is distinct from its design connector. These are guidance entries, not
  declarations that an account or MCP connection was activated.

The deprecated `@railway/mcp-server` package is deliberately not installed. Railway's
current documentation supports its CLI or the official remote OAuth endpoint.
