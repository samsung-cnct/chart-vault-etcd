# Slack notifications

[Slack notifications](https://samsung-cnct.slack.com/apps/search?q=github) can be used to make developers aware of PR/issue and release activiy. To implement this you will need [Admin Privileges](https://help.github.com/articles/repository-permission-levels-for-an-organization/). To ensure that you are not the only one who can maintain these integrations, it is recommended that you grant a GitHub Team (e.g. `commontools`) permissions and not a single individual contributor.  The default notification level for the github integration can be noisy so you only want to have the following Events notify slack:     
- Commit Events  
    - Commits pushed to the repository  
        - Only show commit summaries (no commit messages)  
- Issue / Pull Request Events  
    - Pull request open or closed  
    - Issues opened or closed  
    - Only show titles of new issues and pull requests  
- Other Events  
    - Branch or tag created or deleted  
    - Branch force-pushed  
