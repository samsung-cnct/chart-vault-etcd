# solas
Solas is scaffolding for new repositories hosted by Samsung CNCT. It implements our best practices, such as issue and PR templates, commit hooks, licensing guidelines, and so on.

SOLAS is also an international maritime treaty to ensure ships comply with minimum safety standards in construction, equipment and operation.

# Quickstart

- Determine a [name](http://phrontistery.info/nautical.html) for your project, for example, `zabra`.
- [Create](https://help.github.com/articles/creating-a-new-repository/) a new empty repo under the `samsung-cnct` [org](https://github.com/samsung-cnct) using your new name, for example https://github.com/samsung-cnct/zabra .
- [Duplicate](https://help.github.com/articles/duplicating-a-repository/) this repo (https://github.com/samsung-cnct/solas) and push it to the `zabra` repo you created in the previous step (https://github.com/samsung-cnct/zabra). Note the arguments to clone and push.

```
git clone --bare https://github.com/samsung-cnct/solas.git
cd solas.git
git push --mirror https://github.com/samsung-cnct/zabra.git
cd ..
rm -rf solas-chart.git
```

- [Fork](https://help.github.com/articles/fork-a-repo/) the `zabra` repo (https://github.com/samsung-cnct/zabra) from `samsung-cnct` and begin subimitting PRs.

# Things to consider

- You may want to update the teams [slack notifications](https://samsung-cnct.slack.com/apps/search?q=github) to notify developers of PR and issue activiy. To do this you will need [Admin Privileges](https://help.github.com/articles/repository-permission-levels-for-an-organization/). To ensure that you are not the only one who can maintain these integrations, it is recommended that you grant a GitHub Team (e.g. `commontools`) permissions and not a single individual contributor.

- If your project will be administered by a GitHUb team (e.g. `commontools`), you will need to contact an owner of the `samsung-cnct` organization so they can grant the `commontools` team admin privileges. Reachout in the `#cnct-dev` or `#team-tooltime` Slack channels.

- You will likely need to configure our [Jenkins CI](https://common-jenkins.kubeme.io/) to test, release and deploy changes.
