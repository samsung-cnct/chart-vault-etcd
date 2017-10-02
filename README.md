# solas
Solas is scaffolding for new repositories hosted by Samsung CNCT. It
implements our best practices, such as issue and PR templates, commit hooks,
licensing guidelines, and so on.

We use Jenkins to implement our CI/CD pipelines. There is one Jenkins job for
each GitHub repository. Each job builds, tests and, then deploys an artifact
to Quay.

SOLAS is also an international maritime treaty to ensure ships comply with
minimum safety standards in construction, equipment and operation.

# Quickstart

- Determine a [name](http://phrontistery.info/nautical.html) for your project,
for example, `zabra`.
- [Create](https://help.github.com/articles/creating-a-new-repository/) a
new empty repo under the [`samsung-cnct`](https://github.com/samsung-cnct)
org using the GitHub GUI, for example https://github.com/samsung-cnct/zabra .
- [Duplicate](https://help.github.com/articles/duplicating-a-repository/)
this repo (https://github.com/samsung-cnct/solas) and push it to the `zabra`
repo you created in the previous step. Note the arguments to clone and push.

```
git clone --bare https://github.com/samsung-cnct/solas.git
cd solas.git
git push --mirror https://github.com/samsung-cnct/zabra.git
cd ..
rm -rf solas.git
```

- Configure CI/CD by following the instructions for [GitHub](https://github.com/samsung-cnct/solas/blob/master/docs/github.md), [Quay](https://github.com/samsung-cnct/solas/blob/master/docs/quay.md), and [Jenkins](https://github.com/samsung-cnct/solas/blob/master/docs/jenkins.md).

- Configure [Slack](https://github.com/samsung-cnct/solas/blob/master/docs/slack.md) notifications.

- [Fork](https://help.github.com/articles/fork-a-repo/) the `zabra` repo
(https://github.com/samsung-cnct/zabra) from `samsung-cnct` and begin
submitting PRs.
