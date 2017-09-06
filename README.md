# solas
Solas is scaffolding for new repositories hosted by Samsung CNCT. It implements our best practices, such as issue and PR templates, commit hooks, licensing guidelines, and so on.

SOLAS is also an international maritime treaty to ensure ships comply with minimum safety standards in construction, equipment and operation.

# Quickstart

- Determine a [name](http://phrontistery.info/nautical.html) for your project
- Fork [solas](https://github.com/samsung-cnct/solas)
- [Rename](https://help.github.com/articles/renaming-a-repository/) it
- [Transfer](https://help.github.com/articles/about-repository-transfers/) it to the samsung-cnct organization
- Fork the new repo from samsung-cnct and begin subitting PRs

# Things to consider

- You may want to update the teams [slack notifications](https://samsung-cnct.slack.com/apps/search?q=github) to notify developers of PR and issue activiy. To do this you will need [Admin Privileges](https://help.github.com/articles/repository-permission-levels-for-an-organization/). To ensure that you are not the only one who can maintain these integrations, it is recommended that you grant a GitHub Team (e.g. `commontools`) permissions and not a single individual contributor.

- You will likely need to configure our [Jenkins CI](https://common-jenkins.kubeme.io/) to test, release and deploy changes.
